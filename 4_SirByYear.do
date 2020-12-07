***** 4_SirByYear.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat year_index
contract _all, freq(N) zero
rename year_index year

merge 1:1 year agecat using data/popDK_year_age.dta, assert(match using) nogen


** SIR by year
qui: dstdize N pop agecat, by(year) using(data/popEU_age.dta) format(%12.3g)
matrix sir_y=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_y=sir_y'


*** Export results
** Load
drop _all

svmat double sir_y, name(matcol)
egen Year= seq(), f(1977) t($lastyear) b(1)
label var Year "Year"

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

** Graph (SIR per year)
twoway ///
	(line sir_yAdjuste Year, $line1) /// mean
	(rcap sir_yLeft sir_yRight Year, $line1) /// 95% CI
	, legend(off) /// legend
	xlabel(1977 "1977" 1982 "1982" 1987 "1987" 1992 "1992" 1997 "1997" 2002 "2002" 2007 "2007" 2012 "2012" $lastyear "$lastyear") ///
	xmtick(1977(1)$lastyear) ///
	ylabel(0(1)10) ///
	ytitle("Age-standardized IR" "per 1,000,000 years") //
graph export results/FigSirByYear${exportformat} ${exportoptions}
graph export results/FigSirByYear${exportvector}

** Text
* SIR first to last year
local format = `", 0.1), "%02.1f")"' // 2 significant numbers
local sirfirst_mean = string(round(sir_yAdjusted[1] `format'
local sirfirst_lb = string(round(sir_yLeft[1] `format'
local sirfirst_ub = string(round(sir_yRight[1] `format'

local sirlast_mean = string(round(sir_yAdjusted[_N] `format'
local sirlast_lb = string(round(sir_yLeft[_N] `format'
local sirlast_ub = string(round(sir_yRight[_N] `format'

local foldincrease = string(round(sir_yAdjusted[_N]/sir_yAdjusted[1] `format'


putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("SIR by period")
putdocx paragraph
putdocx text ("SIR increased from `sirfirst_mean' (95%CI `sirfirst_lb'-`sirfirst_ub') in 1977 to `sirlast_mean' (95%CI `sirlast_lb'-`sirlast_ub') in ${lastyear}."), linebreak
putdocx text ("Fold increase from 1977-${lastyear}: `foldincrease'"), linebreak

putdocx save results/TextSirOverall, append