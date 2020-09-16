***** 4_AgeByMod.do *****

*** Calculations
** Cases per age category
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
conv_missing, var(modcat) combmiss("Missing")


assert age<100
egen float age10y = cut(age), at(0(10)100) 
label var age10y "Age at diagnosis"
local i = 1
local labeltext = ""

forvalues agegrp = 0(10)99.9 {
	local from = string(`agegrp', "%2.0f")
	local to = string(`agegrp'+9.9, "%2.1f")
	local labeltext = `"`labeltext' `i' "`from'-`to'" "'
	
	qui: recode age10y (`agegrp'=`i')
	
	local i = `i'+1
}

label define age10y_ `labeltext'
label value age10y age10y_
tab age10y, mi

*** Graph
** Overall
graph bar (count), over(age10y) ///
	bar(1, $bar1) ///
	legend(on order(1 "Total")) ///
	ytitle("N") ylabel(0(25)125) ///
	b1title(Age at diagnosis) // x-axis
graph export results/FigAgeOverall${exportformat} ${exportoptions}

** By sex
graph bar (count),  over(sex) over(age10y) stack asyvars ///
	bar(1, $bar1) bar(2, $bar2)  ///
	legend(order(2 1)) /// reverse legend order
	ytitle("N") ylabel(0(25)125) ///
	b1title(Age at diagnosis) // x-axis
graph export results/FigAgeBySex${exportformat} ${exportoptions}

** By modcat
* Reverse legend order
local legendorder = ""
qui: su modcat
forvalues mod = 1(1)`r(max)' {
		local legendorder = `"`mod' `legendorder'"'
}
di "`legendorder'"

* Bar appearance
local bar = ""
qui: su modcat
forvalues x = `r(min)'(1)`r(max)' {
    local barlayout = `"`barlayout' bar(`x', ${bar`r(max)'_`x'})"'
}
di `"`barlayout'"'

* Graph
graph bar (count) if cohort_simple==1,  over(modcat) over(age10y) stack asyvars ///
	`barlayout'  ///
	legend(order(`legendorder')) /// reverse legend order
	ytitle("N") ylabel(0(10)50) ///
	b1title(Age at diagnosis) // x-axis
graph export results/FigAgeByMod${exportformat} ${exportoptions}