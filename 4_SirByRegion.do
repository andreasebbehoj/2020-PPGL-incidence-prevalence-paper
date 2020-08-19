***** 4_SirByRegion.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat period10y cohort_simple
rename period10y period
contract _all, freq(N) zero

merge 1:1 period cohort_simple agecat using data/popDK_period_age_region.dta, assert(match using) nogen



** SIR by period and region
qui: dstdize N pop agecat, by(period cohort_simple) using(data/popEU_age.dta) format(%12.3g)
matrix sir_p=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_p=sir_p'


*** Export results
** Load
drop _all

svmat double sir_p, name(matcol)
egen period= seq(), f(1) t(4) b(2)
egen cohort_simple= seq(), f(1) t(2) b(1)
label var period "Period"
label value period period10y_

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // SIR Per million
}

* Jitter x-axis
qui: replace period = period-0.01 if cohort_simple==1
qui: replace period = period+0.01 if cohort_simple==2

* Define graphs and legend
qui: su cohort_simple
local legendorder = `r(max)'
local legend = ""
local twoway = ""
forvalues cohort_simple = `r(max)'(-1)1 {
		local twoway = `"(line sir_pAdjusted period if cohort_simple==`cohort_simple', lcolor(${color`r(max)'_`cohort_simple'})) "' /// mean
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label cohort_simple_ `cohort_simple''" `legend'"'
		local legendorder = `legendorder'-1
}
forvalues cohort_simple = `r(max)'(-1)1 {
		local twoway = 	`"`twoway'"' ///
					+ `" (rcap sir_pLeft sir_pRight period if cohort_simple==`cohort_simple', lcolor(${color`r(max)'_`cohort_simple'})) "' // 95% CI
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(1) order(`legend') ) ///
	xlabel(1(1)4,valuelabel) ///
	ylabel(0(1)10) ///
	ytitle("SIR" "per 1,000,000 years") //
graph export results/FigSirByRegion${exportformat} ${exportoptions}