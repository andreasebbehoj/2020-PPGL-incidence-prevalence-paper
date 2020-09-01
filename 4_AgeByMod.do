***** 4_AgeByMod.do *****

*** Calculations
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1

assert age<100
egen float age10y = cut(age), at(0(10)100) 
label var age10y "Age at diagnosis"
local i = 1
local labeltext = ""

forvalues agegrp = 0(10)99.9 {
	local from = string(`agegrp', "%2.0f")
	local to = string(`agegrp'+9.9, "%2.1f")
	local labeltext = `"`labeltext' `i' "`from'-`to'" "'
	
	recode age10y (`agegrp'=`i')
	
	local i = `i'+1
}

label define age10y_ `labeltext'
label value age10y age10y_
di `"`labeltext'"'

** Age histogram (all of DK)
twoway (histogram age10y, discrete frequency fcolor($color1) lcolor(none)) ///
		, xlabel(`labeltext', labels) ylabel(0(30)150) ytitle("N")
graph export results/FigAgeOverall${exportformat} ${exportoptions}


** Age histogram by modcat (CRNR only)
keep if cohort_simple==1
tab age10y
keep age10y modcat
contract _all, freq(N) zero
bysort age10y (modcat): gen cumu = sum(N)


* Define graphs and legend
qui: su modcat
local legendorder = `r(max)'
forvalues mod = 1(1)`r(max)' {
		local twoway = "(bar cumu age10y if modcat==`mod'" /// bar chart
					+ `", lcolor(none) fcolor(${color`r(max)'_`mod'})) "' /// Colors
					+ `"`twoway'"' // Append
		local legend = `"`legendorder' "`: label modcat_ `mod''" `legend'"'
		local legendorder = `legendorder'-1
}

* Export
di `"`twoway'"' _n(2) `"`legend'"' _n(2) `"`xlabel'"'
twoway `twoway', ///
	legend(on col(2) colfirst order(`legend') ) ///
	xlabel(`labeltext') ///
	ylabel(0(10)50) ///
	ytitle("N") //
graph export results/FigAgeByMod${exportformat} ${exportoptions}

