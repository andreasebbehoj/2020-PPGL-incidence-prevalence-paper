***** 4_Prev.do *****
/* 
This do file:
- Counts N prevalent each year by sex and agecat
- Makes a figure with age-standardized prevalence each year
- Makes a table of prevalence at end of study by sex with age-specific (crude) prevalences and total (age-standardized) prevalences
*/


***** Prepare data
use data/cohort_pid.dta, clear

*** Generate empty data frame for results for table
capture: frames drop table
frame create table
frame table {
	set obs 1
	gen grp = .
	gen rowname = ""
	gen cell_0 = "Total"
	gen cell_1 = "Men"
	gen cell_2 = "Women"   
}
local x = 1
qui: levelsof agecat, local(agecats) clean
foreach row in -1 `agecats' 0 {
    local rowname : label agecat_ `row'
	di "`rowname'"
	local x = `x'+1
	qui: frame table: set obs `x'
	qui: frame table: replace rowname="    `rowname'" if _n==_N
	qui: frame table: replace grp=`row' if _n==_N
}
qui: frame table: replace rowname="Total" if grp==0
qui: frame table: replace rowname="Age" if grp==-1
qui: frame table: replace rowname = subinstr(rowname, "{&ge}", ustrunescape("\u2265"), 1) // equal-or-above-sign

*** Determine prevalent patients per year (from diagnosis to death/emigration)
keep cpr d_foddato date_index c_status d_status_hen_start

* Import history of residences (registry data)
merge 1:m cpr using regdata/PlaceOfResidence.dta, keep(match) assert(match using) nogen

* Evaluate if index date match address in Denmark
forvalues year=1977(1)$lastyear {
	qui: gen N`year' = 1 if /// Prevalent year of diagnosis
			year(date_index)==`year' ///
			& inrange(`year', year(dk_adresse_start), year(dk_adresse_slut))
	
	qui: recode N`year' (.=1) if /// Prevalent 31dec subsequent years
			date_index <= date("31-12-`year'", "DMY") /// Prevalent from diagnosis..
			& inrange(date("31-12-`year'", "DMY"), dk_adresse_start, dk_adresse_slut) /// .. while address is in DK..
			& d_status > date("31-12-`year'", "DMY") // .. to date of death/emigration 
	* Determine patient age each year
	qui: gen age`year' = floor((date("31-12-`year'", "DMY")-d_foddato)/365)
	qui: recode age`year' $agecat if N`year'==1, gen(agecat`year') label(agecat`year'_)
}

* Summarize prevalence by person
collapse (max) agecat* N* , by(cpr) 
tempfile personprev
save `personprev', replace

use data/cohort_pid.dta, clear
keep cpr sex
merge 1:1 cpr using `personprev', nogen assert(match)


* Summarize prevalence for each year
reshape long agecat N, i(cpr) j(year)
label value agecat agecat_
drop if N==.
drop cpr N
contract year sex agecat, freq(N) zero

* Add population
merge 1:1 year agecat sex using data/popDK_year_age_sex.dta, assert(match using) nogen

tempfile prevdata
save `prevdata', replace


***** Calculate prevalence
use `prevdata', clear

*** N prevalent at end of study (report)
qui: su N if year==$lastyear
global Nprev = `r(sum)'


*** Prevalence by year (figure and report)
dstdize N pop agecat, by(year) using(data/popEU_age.dta) format(%12.3g)
matrix prev_y=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix prev_y=prev_y'

* Load results
drop _all
svmat double prev_y, name(matcol)
egen Year= seq(), f(1977) t($lastyear) b(1)
label var Year "Year"

* Change to prevalence per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

* Graph (prevalence by year)
twoway ///
	(line prev_yAdjuste Year, $line1) /// mean
	(rcap prev_yLeft prev_yRight Year, $line1) /// 95% CI
	, legend(off) /// legend
	xlabel(1977 "1977" 1982 "1982" 1987 "1987" 1992 "1992" 1997 "1997" 2002 "2002" 2007 "2007" 2012 "2012" $lastyear "$lastyear") ///
	xmtick(1977(1)$lastyear) ///
	/// ylabel(0(1)10) ///
	ytitle("Age-standardized prevalence" "per 1,000,000 years") //
graph export results/FigPrevByYear${exportformat} ${exportoptions}
graph export results/FigPrevByYear${exportvector}

* Text (prevalence at end of study)
local prev = string(round(prev_yAdjusted[_N], 0.1), "%3.1f") /// estimate
							+ " (" /// 
							+ string(round(prev_yLeft[_N], 0.1), "%3.1f") /// lower
							+ "-" ///
							+ string(round(prev_yRight[_N], 0.1), "%3.1f") /// upper
							+ ")"

putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("Prevalence")
putdocx paragraph
putdocx text ("Prevalence of PPGL patients alive and living in Denmark in $lastyear (n=${Nprev}): `prev'"), linebreak
putdocx save results/TextPrevLastyear, replace



*** Table (prevalence at end of study)
* Total, age-standardized 
qui: frame table: replace cell_0="`prev'" if grp==0


* By sex, age-standardized
use `prevdata', clear
keep if year==$lastyear
gen dummy=1

foreach sex in 1 2 {
	qui: dstdize N pop agecat if sex==`sex', by(dummy) using(data/popEU_age.dta) format(%12.3g)
	matrix prev=  r(adj) \ r(lb) \ r(ub)
	local prev = string(round(prev[1,1]*1000000, 0.1), "%3.1f") /// estimate
								+ " (" /// 
								+ string(round(prev[2,1]*1000000, 0.1), "%3.1f") /// lower
								+ "-" ///
								+ string(round(prev[3,1]*1000000, 0.1), "%3.1f") /// upper
								+ ")"
	qui: frame table: replace cell_`sex'="`prev'" if grp==0
	di "Total, sex `sex'" _col(20) "`prev'"
}

* Total, age-specific (crude)
qui: levelsof agecat, local(agecats) clean
foreach row in `agecats' {
	qui: ci means N if agecat==`row', poisson exposure(pop)
	local prev = string(round(`r(mean)'*1000000, 0.1), "%3.1f") /// estimate
							+ " (" /// 
							+ string(round(`r(lb)'*1000000, 0.1), "%3.1f") /// lower
							+ "-" ///
							+ string(round(`r(ub)'*1000000, 0.1), "%3.1f") /// upper
							+ ")"
	qui: frame table: replace cell_0="`prev'" if grp==`row'
	di "Agecat `row', all:" _col(20) "`prev'"
}

* By sex, age-specific (crude)	
list, clean
qui: levelsof agecat, local(agecats) clean
foreach row in `agecats' {
	di "Agecat `row'"
	foreach sex in 1 2 {
		qui: ci means N if agecat==`row' & sex==`sex', poisson exposure(pop)
		local prev = string(round(`r(mean)'*1000000, 0.1), "%3.1f") /// estimate
							+ " (" /// 
							+ string(round(`r(lb)'*1000000, 0.1), "%3.1f") /// lower
							+ "-" ///
							+ string(round(`r(ub)'*1000000, 0.1), "%3.1f") /// upper
							+ ")"
		qui: frame table: replace cell_`sex'="`prev'" if grp==`row'
		di _col(5) "sex `sex':" _col(20) "`prev'"	
	}
}

frame table: save results/TabPrevBySexAge.dta, replace
capture: frame drop table