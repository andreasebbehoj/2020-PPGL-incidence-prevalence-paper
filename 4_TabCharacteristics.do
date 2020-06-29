***** 4_TabCharacteristics.do *****
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1

/** Text
putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("Patient Characteristics")
putdocx paragraph
*/

** Define column headers
label define period10y_ 0 "Total", modify
local collist = "0 1 2 3 4"

* Total N per column
foreach col of local collist {
	local label`col' : label period10y_ `col'
	di " `col' - `label`col''"
	
	if `col'==0 {
		count
	}
	else {
		count if period10y==`col'
	}
	local coltotal_`col' = `r(N)'
}

** Categorical vars
foreach var in cohort_simple sex agecat modcat sizecat sympcat biocat tumorcat {
	di "`var'"
	preserve
	
	* Count each category
	if inlist("`var'", "cohort_simple", "sex", "agecat") { // Available for all of DK
		qui: statsby, by(period10y `var') clear : count
	}
	else { // Only available in North and Central regions
		qui: statsby, by(period10y `var') clear : count if cohort_simple==1
	}
	
		
	* Reshape
	qui: reshape wide N , i(`var') j(period10y) 
	
	* Calculate rowtotal
	qui: egen N0 = rowtotal(N*)
	
	* Calculate column percentage
	foreach col of local collist {
		qui: egen perc_`col' = pc(N`col')
		qui: gen cell_`col' = 	string(N`col') /// N
							+ " (" ///
							+ string(round(perc_`col', 0.1), "%3.1f") ///
							+ ")"
	drop N`col' perc_`col'
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
	statsby, by(period10y) clear total: su `var' if cohort_simple==1, detail
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
	qui: recode period10y (.=0)
	keep var var firstcol seccol period10y cell_
	reshape wide cell_, i(var) j(period10y)
	
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
foreach var in cohort_simple sex agecat age modcat sizecat sizemax sympcat sympyears biocat biomax tumorcat {
	qui: append using `results_`var''
}

* Format first column
replace seccol = subinstr(seccol, "{&ge}", ustrunescape("\u2265"), 1) // equal-or-above-sign
gen rowname = firstcol
replace rowname = "    " + seccol if mi(rowname)

* Format cells
ds cell*
foreach var in `r(varlist)' {
	replace `var' = "-" if `var'==". (.)"
}

** Export to table
putdocx clear
putdocx begin, landscape
putdocx paragraph
putdocx table tbl1 = data("rowname cell_0 cell_1 cell_2 cell_3 cell_4"), width(100%) layout(autofitcontents)
putdocx table tbl1(., .), ${tablecells} 
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
gen row = _n
levelsof row if !mi(firstcol) & mi(seccol)
putdocx table tbl1(`r(levels)', .), ${tablerows}
putdocx save results/TabCharacteristics, replace