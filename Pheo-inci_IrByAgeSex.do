***** Pheo-inci_IrByAge.do *****

*** Calculations
** Cases per year
use cohort_ppgl.dta, clear
keep if ppgl_incident==1

keep agecat sex period10y
rename period10y period
contract _all, freq(N) zero

merge 1:1 agecat sex period using popDK_ageperiod.dta, assert(match using) nogen


** IR by period/age and period/sex
tempfile byage 
statsby, by(period agecat) saving(`byage', replace): ci means N, poisson exposure(pop)
tempfile bysex 
statsby, by(period sex) saving(`bysex', replace): ci means N, poisson exposure(pop)


*** Graph by age
* Change to SIR per million
use `byage', clear
foreach var in mean lb ub {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

* Define graphs and legend
qui: su agecat
local legendorder = `r(max)'
forvalues age = 1(1)`r(max)' {
		local twoway = `"(line mean period if agecat==`age', lcolor(${color4_`age'})) "' /// mean
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label agecat_ `age''" `legend'"'
		local legendorder = `legendorder'-1
}
forvalues age = 1(1)`r(max)' {
		local twoway = 	`"`twoway'"' ///
					+ `" (rcap lb ub period if agecat==`age', lcolor(${color4_`age'})) "' // 95% CI
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(1) order(`legend') ) ///
	xlabel(1(1)4,valuelabel) ///
	ylabel(0(1)10) ///
	ytitle("IR" "per 1,000,000 years") //
graph export Results_FigIrByAge${exportformat} ${exportoptions}

putdocx begin
putdocx paragraph, halign(center)
putdocx image Results_FigIrByAge${exportformat}, height(5 in)
putdocx save Results_FigIrByAge, replace


*** Graph by sex
* Change to SIR per million
use `bysex', clear
foreach var in mean lb ub {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

* Define graphs and legend
qui: su sex
local legendorder = `r(max)'
local legend = ""
local twoway = ""
forvalues sex = 1(1)`r(max)' {
		local twoway = `"(line mean period if sex==`sex', lcolor(${color4_`sex'})) "' /// mean
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label sex_ `sex''" `legend'"'
		local legendorder = `legendorder'-1
}
forvalues sex = 1(1)`r(max)' {
		local twoway = 	`"`twoway'"' ///
					+ `" (rcap lb ub period if sex==`sex', lcolor(${color4_`sex'})) "' // 95% CI
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(1) order(`legend') ) ///
	xlabel(1(1)4,valuelabel) ///
	ylabel(0(1)10) ///
	ytitle("IR" "per 1,000,000 years") //
graph export Results_FigIrBySex${exportformat} ${exportoptions}

putdocx begin
putdocx paragraph, halign(center)
putdocx image Results_FigIrBySex${exportformat}, height(5 in)
putdocx save Results_FigIrBySex, replace