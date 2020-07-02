***** 4_IrByAge.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1

keep agecat sex period10y
rename period10y period
contract _all, freq(N) zero

merge 1:1 agecat sex period using data/popDK_ageperiod.dta, assert(match using) nogen


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

* Jitter x-axis
qui: replace period = period-0.03 if agecat==1
qui: replace period = period-0.01 if agecat==2
qui: replace period = period+0.01 if agecat==3
qui: replace period = period+0.03 if agecat==4

* Define graphs and legend
qui: su agecat
local legendorder = `r(max)'
forvalues age = 1(1)`r(max)' {
		local twoway = `"(line mean period if agecat==`age', lcolor(${color`r(max)'_`age'})) "' /// mean
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label agecat_ `age''" `legend'"'
		local legendorder = `legendorder'-1
}
forvalues age = 1(1)`r(max)' {
		local twoway = 	`"`twoway'"' ///
					+ `" (rcap lb ub period if agecat==`age', lcolor(${color`r(max)'_`age'})) "' // 95% CI
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(1) order(`legend') ) ///
	xlabel(1(1)4,valuelabel) ///
	ylabel(0(1)10) ///
	ytitle("IR" "per 1,000,000 years") //
graph export results/FigIrByAge${exportformat} ${exportoptions}


*** Graph by sex
* Change to SIR per million
use `bysex', clear
foreach var in mean lb ub {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

* Jitter x-axis
qui: replace period = period-0.01 if sex==1
qui: replace period = period+0.01 if sex==2

* Define graphs and legend
qui: su sex
local legendorder = `r(max)'
local legend = ""
local twoway = ""
forvalues sex = 1(1)`r(max)' {
		local twoway = `"(line mean period if sex==`sex', lcolor(${color`r(max)'_`sex'})) "' /// mean
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label sex_ `sex''" `legend'"'
		local legendorder = `legendorder'-1
}
forvalues sex = 1(1)`r(max)' {
		local twoway = 	`"`twoway'"' ///
					+ `" (rcap lb ub period if sex==`sex', lcolor(${color`r(max)'_`sex'})) "' // 95% CI
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(1) order(`legend') ) ///
	xlabel(1(1)4,valuelabel) ///
	ylabel(0(1)10) ///
	ytitle("IR" "per 1,000,000 years") //
graph export results/FigIrBySex${exportformat} ${exportoptions}