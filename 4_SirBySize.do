***** 4_SirBySize.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep if cohort_simple==1 // Central and Northern Regions only
keep agecat period10y sizecat
rename period10y period
contract _all, freq(N) zero

merge m:1 period agecat using data/popRegion_age_period.dta, assert(match using) nogen


** Sir by period and sizecat
qui: dstdize N pop agecat, by(period sizecat) using(data/popEU_age.dta) format(%12.3g)

matrix sir=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir=sir'

*** Export
** Save labels
levelsof period, local(periods)
levelsof sizecat, local(sizecats)

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
gen Size = .
local obs = 1
foreach per of local periods {
    foreach size of local sizecats {
		qui: replace Period = `per' if _n==`obs' // "`: label period_ `per''"
		qui: replace Size = `size' if _n==`obs' // "`: label sizecat_ `size''"
		local obs = `obs'+1
	}
}
label values Period period_
label values Size sizecat_

** Graph (SIR by sizecat and period)
bysort Period (Size): gen sir = sum(sirAdjusted) if sirAdjusted!=0 // Cumulative value for stacked bars

* Define graphs and legend
qui: su Size
local legendorder = `r(max)'
forvalues size = 1(1)`r(max)' {
		local twoway = "(bar sir Period if Size==`size'" /// bar chart
					+ `", lcolor(none) fcolor(${color8_`size'})) "' /// Colors
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label sizecat_ `size''" `legend'"'
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
graph export results/FigSirBySize${exportformat} ${exportoptions}

putdocx begin
putdocx paragraph, halign(center)
putdocx image results/FigSirBySize${exportformat}, height(5 in)
putdocx save results/FigSirBySize, replace
