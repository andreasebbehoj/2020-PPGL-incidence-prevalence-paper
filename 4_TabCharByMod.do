***** 4_TabCharByMod.do *****
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep if cohort_simple==1

** Missing
count if modcat==8 
global nmodmissing = `r(N)'
drop if modcat==8

** Define column headers
label define modcat_ 0 "Total", modify
local collist = "0 1 2 3 4 5 6 7"

* Total N per column
foreach col of local collist {
	local label`col' : label modcat_ `col'
	di " `col' - `label`col''"
	
	if `col'==0 {
		count
	}
	else {
		count if modcat==`col'
	}
	local coltotal_`col' = `r(N)'
}

** Categorical vars
foreach var in sex agecat surgcat sizecat sympcat htncat biocat tumorcat gencat {
	di "`var'"
	preserve
	
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
	qui: replace seccol = seccol + ", n(%)"
	
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
	statsby, by(modcat) clear total: su `var', detail
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
	reshape wide cell_, i(var) j(modcat)
	
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
set obs 2
gen var = " "
gen firstcol = "Patients, n " if _n==2
gen seccol = " "
foreach col of local collist {
	di " `col' - `label`col''"
	qui: gen cell_`col' = "`label`col''" if _n==1
	qui: replace cell_`col' = "`coltotal_`col''" if _n==2
}

* Appending results
foreach var in sex agecat age sympcat sympyears htncat surgcat sizecat sizemax tumorcat biocat biomax gencat {
	qui: append using `results_`var''
}

* Format first column
replace seccol = subinstr(seccol, "{&ge}", ustrunescape("\u2265"), 1) // equal-or-above-sign
gen rowname = firstcol
replace rowname = "    " + seccol if mi(rowname)

* Format cells
ds cell*
foreach var in `r(varlist)' {
	replace `var' = "-" if `var'==". (.)" | !mi(seccol) & mi(`var')
}
gen row = _n

** Export 
save results/TabCharByMod.dta, replace