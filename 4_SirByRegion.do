***** 4_SirByRegion.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat period10y cohort_simple
rename period10y period
contract _all, freq(N) zero

merge 1:1 period cohort_simple agecat using data/popDK_period_age_region.dta, assert(match using) nogen



** SIR by year
qui: dstdize N pop agecat, by(year cohort_simple) using(data/popEU_age.dta) format(%12.3g)
matrix sir_y=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_y=sir_y'


*** Export results
** Load
drop _all

svmat double sir_y, name(matcol)
egen Year= seq(), f(1977) t($lastyear) b(2)
egen Region= seq(), f(1) t(2) b(1)
label var Year "Year"

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

** Table (SIR per year)
ds Year, not
foreach var in `r(varlist)' {
	qui: tostring `var', force replace format(%03.2f)
}
rename sir_yCrude Crude
gen SIR = sir_yAdjusted + " (" + sir_yLeft + "-" + sir_yRight + ")"

save results/TabSirByRegion.dta, replace