***** 4_SirBySymp.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep if cohort_simple==1 // Central and Northern Regions only
conv_missing, var(sympcat) combmiss("Missing")
keep period10y agecat cohort_simple sympcat
rename period10y period
contract _all, freq(N) zero

merge m:1 period agecat cohort_simple using data/popDK_period_age_region.dta, assert(match using) nogen
keep if cohort_simple==1 

** Sir by period and sympcat
qui: dstdize N pop agecat, by(period sympcat) using(data/popEU_age.dta) format(%12.3g)

matrix sir=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir=sir'

*** Export
** Save labels
levelsof period, local(periods)
levelsof sympcat, local(sympcats)

** Load
drop _all
svmat double sir, name(matcol)

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

** Add labels
gen Period = .
gen Symptoms = .
local obs = 1
foreach per of local periods {
    foreach symp of local sympcats {
		qui: replace Period = `per' if _n==`obs' // "`: label period_ `per''"
		qui: replace Symptoms = `symp' if _n==`obs' // "`: label sympcat_ `symp''"
		local obs = `obs'+1
	}
}
label values Period period_
label values Symptoms sympcat_

** Graph (SIR by sympcat and period)
bysort Period (Symptoms): gen sir = sum(sirAdjusted) if sirAdjusted!=0 // Cumulative value for stacked bars

* Define graphs and legend
qui: su Symptoms
local legendorder = `r(max)'
forvalues symp = 1(1)`r(max)' {
		local twoway = "(bar sir Period if Symptoms==`symp'" /// bar chart
					+ `", lcolor(none) fcolor(${color`r(max)'_`symp'})) "' /// Colors
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label sympcat_ `symp''" `legend'"'
		local legendorder = `legendorder'-1
}

* Define x axis label
qui: levelsof Period
foreach per in `r(levels)' {
    di `"``xlabel''"'
	local xlabel = `"`xlabel' `per' "`: label period_ `per''" "'
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(1) order(`legend') ) ///
	xlabel(`xlabel') ///
	ylabel(0(1)5) ///
	ytitle("Age-standardized IR" "per 1,000,000 years") //
graph export results/FigSirBySymp${exportformat} ${exportoptions}