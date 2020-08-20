***** 4_SirByMod.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep if cohort_simple==1 // Central and Northern Regions only
keep agecat cohort_simple period10y modcat
rename period10y period
contract _all, freq(N) zero

merge m:1 period cohort_simple agecat using data/popDK_period_age_region.dta, assert(match using) nogen
keep if cohort_simple==1 // Central and Northern Regions only

** Sir by period and modcat
qui: dstdize N pop agecat, by(period modcat) using(data/popEU_age.dta) format(%12.3g)

matrix sir=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir=sir'

*** Export
** Save labels
levelsof period, local(periods)
levelsof modcat, local(modcats)

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
gen ModeOfDiscovery = .
local obs = 1
foreach per of local periods {
    foreach mod of local modcats {
		qui: replace Period = `per' if _n==`obs' // "`: label period_ `per''"
		qui: replace ModeOfDiscovery = `mod' if _n==`obs' // "`: label modcat_ `mod''"
		local obs = `obs'+1
	}
}
label values Period period_
label values ModeOfDiscovery modcat_

** Graph (SIR by modcat and period)
bysort Period (ModeOfDiscovery): gen sir = sum(sirAdjusted) if sirAdjusted!=0 // Cumulative value for stacked bars

* Define graphs and legend
qui: su ModeOfDiscovery
local legendorder = `r(max)'
forvalues mod = 1(1)`r(max)' {
		local twoway = "(bar sir Period if ModeOfDiscovery==`mod'" /// bar chart
					+ `", lcolor(none) fcolor(${color`r(max)'_`mod'})) "' /// Colors
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label modcat_ `mod''" `legend'"'
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
	legend(on col(2) colfirst order(`legend') ) ///
	xlabel(`xlabel') ///
	ylabel(0(1)5) ///
	ytitle("Age-standardized IR" "per 1,000,000 years") //
graph export results/FigSirByMod${exportformat} ${exportoptions}
