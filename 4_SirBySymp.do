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

** Save labels
levelsof period, local(periods)
levelsof sympcat, local(sympcats)

** Load results
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

*** Graph
** Reverse legend order
local legend = ""
qui: su Symptoms
forvalues x = `r(max)'(-1)`r(min)' {
    local legend = "`legend' `x'"
}
di "`legend'"

** Bar appearance
local bar = ""
qui: su Symptoms
forvalues x = `r(min)'(1)`r(max)' {
    local barlayout = `"`barlayout' bar(`x', ${bar`r(max)'_`x'})"'
}
di `"`barlayout'"'

** Graph 
graph bar (first) sirAdjusted, over(Symptoms) over(Period) ///
	asyvars stack ///
	legend(order(`legend')) /// reverse legend order
	`barlayout' ///
	ytitle("Age-standardized IR" "per 1,000,000 years") ///
	ylabel(0/5)
graph export results/FigSirBySymp${exportformat} ${exportoptions}
graph export results/FigSirBySymp${exportvector}