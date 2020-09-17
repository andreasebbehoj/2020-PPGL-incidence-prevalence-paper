***** 4_TabCharByMod.do *****
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep if cohort_simple==1
global footnote_TabCharByMod_miss = ""

** Missing
drop if mi(modcat)

** Define column headers
label define modcat_ 0 "Total", modify
local collist = "0 1 2 3 4 5 6 7"

* Total N per column
foreach col of local collist {
	local label`col' : label modcat_ `col'
	if `col'==0 {
		qui: count
	}
	else {
		qui: count if modcat==`col'
	}
	local coltotal_`col' = `r(N)'
	di " `col' - `label`col'' (n=`coltotal_`col'')"
}

** Categorical vars
foreach var in sex agecat sizecat sympcat sympycat htncat biocat tumorcat gencat surgcat {
	di "`var'"
	preserve
	
	* Count missing footnote
	qui: levelsof `var' if mi(`var'), missing clean local(missing)
	if !mi("`missing'") {
			local varname : var label `var'
			global footnote_TabCharByMod_miss = "$footnote_TabCharByMod_miss" + "`varname' ("
			foreach cat of local missing {
				local catname : label `var'_ `cat'
				qui: count if `var'==`cat'
				local missno = `r(N)'
				global footnote_TabCharByMod_miss = "$footnote_TabCharByMod_miss" + "`missno' `catname', "
			}
		global footnote_TabCharByMod_miss = "$footnote_TabCharByMod_miss" + "), "
		}
	
	* Count each category
	qui: statsby, by(modcat `var') clear : count
	
	* Reshape
	qui: reshape wide N , i(`var') j(modcat) 
	
	* Calculate rowtotal
	qui: egen N0 = rowtotal(N*)
	
	* Calculate column percentage
	foreach col of local collist {
		capture: egen perc_`col' = pc(N`col')
		capture: gen cell_`col' = 	string(N`col') /// N
							+ " (" ///
							+ string(round(perc_`col', 0.1), "%3.1f") ///
							+ ")"
	capture: drop N`col' perc_`col'
	}
	
	* Row names (subgroups)
	qui: decode `var', gen(seccol)
	qui: replace seccol = seccol + ", n (%)"
	
	* Row names (var group)
	local name : variable label `var'
	local obsno = _N+1
	qui: set obs `obsno'
	qui: gen firstcol = "`name'" if _n==_N
	
	qui: gen var = "`var'"
	
	* Sort and order
	gsort -firstcol +`var'
	qui: drop `var'
	order var firstcol seccol cell_0 cell_*
	
	* Save
	tempfile results_`var'
	qui: save `results_`var'', replace
	
	restore
}


** Continous results
foreach var in age sizemax biomax sympyears { //  
	di "`var'"
	preserve
	
	local name : variable label `var'
	
	* Calculate median and range
	qui: statsby, by(modcat) clear total: su `var', detail
	gen cell_ = string(round(p50, 0.1), "%3.1f") /// Median
							+ " (" /// 
							+ string(round(min, 0.1), "%3.1f") /// min
							+ "-" ///
							+ string(round(max, 0.1), "%3.1f") /// max
							+ ")"
	
	* Row names (var group)
	qui: gen firstcol = "`name', median (range)" 
	qui: gen seccol = " "
	qui: gen var = "`var'"
	
	* Reshape 
	qui: recode modcat (.=0)
	keep var var firstcol seccol modcat cell_
	qui: reshape wide cell_, i(var) j(modcat)
	
	* Order
	order var firstcol seccol cell_0 cell_*
	
	* Save
	tempfile results_`var'
	qui: save `results_`var'', replace
	
	restore
}

** Combining results
* Headings and N 
drop _all
qui: set obs 2
gen var = " "
qui: gen firstcol = "Patients, n " if _n==2
gen seccol = " "
foreach col of local collist {
	di " `col' - `label`col''"
	qui: gen cell_`col' = "`label`col''" if _n==1
	qui: replace cell_`col' = "`coltotal_`col''" if _n==2
}

* Appending results
foreach var in sex agecat age sympcat sympycat sympyears htncat sizecat sizemax tumorcat biocat biomax gencat surgcat {
	qui: append using `results_`var''
}

* Format first column
qui: replace seccol = subinstr(seccol, "{&ge}", ustrunescape("\u2265"), 1) // equal-or-above-sign
qui: gen rowname = firstcol
qui: replace rowname = "    " + seccol if mi(rowname)

* Format cells
qui: ds cell*
foreach var in `r(varlist)' {
	qui: replace `var' = "-" if `var'==". (.)" | !mi(seccol) & mi(`var')
}
gen row = _n

** Export 
global footnote_TabCharByMod_miss = subinstr("$footnote_TabCharByMod_miss", ", )", ")", .)
di "Reasons for missing data: $footnote_TabCharByMod_miss"

save results/TabCharByMod.dta, replace