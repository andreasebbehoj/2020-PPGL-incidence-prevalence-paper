***** 4_Prev.do *****


*** Years prevalent 
use data/cohort_pid.dta, clear
keep cpr date_index c_status d_status_hen_start

** Import history of residences (registry data)
merge 1:m cpr using regdata/PlaceOfResidence.dta, keep(match) assert(match using) nogen

** Evaluate if index date match address in Denmark
forvalues year=1977(1)$lastyear {
	qui: gen N`year' = 1 if /// Prevalent year of diagnosis
			year(date_index)==`year' ///
			& inrange(`year', year(dk_adresse_start), year(dk_adresse_slut))
	
	qui: recode N`year' (.=1) if /// Prevalent 31dec subsequent years
			date_index <= date("31-12-`year'", "DMY") /// Prevalent from diagnosis..
			& inrange(date("31-12-`year'", "DMY"), dk_adresse_start, dk_adresse_slut) /// .. while address is in DK..
			& d_status > date("31-12-`year'", "DMY") // .. to date of death/emigration 
}


** Summarize by person
collapse (max) N*, by(cpr) 
tempfile prevdata
save `prevdata', replace


** Summarize by year and age cat
use data/cohort_pid.dta, clear
merge 1:1 cpr using `prevdata', nogen assert(match)

count if N$lastyear==1 // Count N prevalent at end of study
local Nprev = `r(N)'

collapse (sum) N*, by(agecat)
reshape long N, i(agecat) j(year)
label variable year "Year"


*** Calculate prevalence
merge 1:1 year agecat using data/popDK_year_age.dta, assert(match using) nogen

** End of study
gen dummy=1
dstdize N pop agecat if year==$lastyear, by(dummy) using(data/popEU_age.dta) format(%12.3g)

local format = `", 0.1), "%03.1f")"' // 3 significant numbers
local prev_mean = string(round(r(adj)[1,1]*1000000 `format'
local prev_lb = string(round(r(lb_adj)[1,1]*1000000 `format'
local prev_ub = string(round(r(ub_adj)[1,1]*1000000 `format'


** By year
dstdize N pop agecat, by(year) using(data/popEU_age.dta) format(%12.3g)
matrix prev_y=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix prev_y=prev_y'



*** Export results
** Load
drop _all
svmat double prev_y, name(matcol)
egen Year= seq(), f(1977) t($lastyear) b(1)
label var Year "Year"

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}


** Graph (prev by year)
twoway ///
	(line prev_yAdjuste Year, $line1) /// mean
	(rcap prev_yLeft prev_yRight Year, $line1) /// 95% CI
	, legend(off) /// legend
	xlabel(1977 "1977" 1982 "1982" 1987 "1987" 1992 "1992" 1997 "1997" 2002 "2002" 2007 "2007" 2012 "2012" $lastyear "$lastyear") ///
	xmtick(1977(1)$lastyear) ///
	/// ylabel(0(1)10) ///
	ytitle("Age-standardized prevalence" "per 1,000,000 years") //
graph export results/FigPrevByYear${exportformat} ${exportoptions}


** Text
putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("Prevalence")
putdocx paragraph
putdocx text ("Prevalence of PPGL patients alive and living in Denmark in $lastyear (n=`Nprev'): `prev_mean' (95%CI `prev_lb'-`prev_ub')"), linebreak
putdocx save results/TextPrevLastyear, replace