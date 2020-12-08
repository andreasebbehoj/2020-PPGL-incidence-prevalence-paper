***** 4_TabCharByPeriod.do *****
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
global footnote_TabCharByPeriod_miss = ""

** Define column headers
label define period10y_ 0 "Total", modify
local collist = "0 1 2 3 4"

* N total cohort per column
foreach col of local collist {
	local label`col' : label period10y_ `col'
	if `col'==0 {
		qui: count
	}
	else {
		qui: count if period10y==`col'
	}
	local coltotal_`col' = `r(N)'
	di " `col' - `label`col'' (n=`coltotal_`col'')"
}

* N clinical cohort per column
foreach col of local collist {
	local label`col' : label period10y_ `col'
	if `col'==0 {
		qui: count if cohort_simple==1
	}
	else {
		qui: count if period10y==`col' & cohort_simple==1
	}
	local colclin_`col' = `r(N)'
	di " `col' - `label`col'' (n=`colclin_`col'')"
}

** Categorical vars
foreach var in sex agecat modcat sizecat sympcat sympycat htncat biocat tumorcat gencat surgcat {
	di "`var'"
	preserve
	
	* Count each category
	if inlist("`var'", "sex", "agecat") { // Available for all of DK
		qui: statsby, by(period10y `var') clear : count
	}
	else { // Only available in North and Central regions
		
		* Count missing footnote
		qui: levelsof `var' if cohort_simple==1 & mi(`var'), missing clean local(missing)
		if !mi("`missing'") {
			local varname : var label `var'
			global footnote_TabCharByPeriod_miss = "$footnote_TabCharByPeriod_miss" + "`varname' ("
			foreach cat of local missing {
				local catname : label `var'_ `cat'
				qui: count if `var'==`cat' & cohort_simple==1
				local missno = `r(N)'
				global footnote_TabCharByPeriod_miss = "$footnote_TabCharByPeriod_miss" + "`missno' `catname', "
			}
		global footnote_TabCharByPeriod_miss = "$footnote_TabCharByPeriod_miss" + "), "
		}
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
	qui: replace seccol = seccol + ", n (%)"
	
	* Row names (var group)
	local name : variable label `var'
	local obsno = _N+1
	qui: set obs `obsno'
	qui: gen firstcol = "`name'" if _n==_N
	
	qui: gen var = "`var'"
	
	* Only available in North and Central regions
	if inlist("`var'", "sex", "agecat")==0 {
		qui: gen onlyavailable = 1 if !mi(firstcol)
	}
	
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
	if "`var'"=="age" {
		qui: statsby, by(period10y) clear total: su `var', detail
	}
	else {  // Only available in North and Central regions
		qui: statsby, by(period10y) clear total: su `var' if cohort_simple==1, detail
	}
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
	qui: reshape wide cell_, i(var) j(period10y)
	
	* Order
	order var firstcol seccol cell_0 cell_*
	
	* Save
	tempfile results_`var'
	qui: save `results_`var'', replace
	
	restore
}

** Combining results
* Headings and N total cohort
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
* N clinical cohort
qui: set obs 3
replace var = " " if _n==3
qui: replace firstcol = "Patients with clinical data, n " if _n==3
qui: replace seccol = " " if _n==3
foreach col of local collist {
	di " `col' - `label`col''"
	qui: replace cell_`col' = "`colclin_`col''" if _n==3
}

* Appending results
foreach var in sex agecat age modcat sympcat sympycat sympyears htncat sizecat sizemax tumorcat biocat biomax gencat surgcat {
	qui: append using `results_`var''
}

* Format first column
qui: replace seccol = subinstr(seccol, "{&ge}", ustrunescape("\u2265"), 1) // equal-or-above-sign
qui: gen rowname = firstcol
qui: replace rowname = "    " + seccol if mi(rowname)

* Format cells
qui: ds cell*
foreach var in `r(varlist)' {
	qui: replace `var' = "-" if `var'==". (.)"
}
gen row = _n


*** Export 
save results/TabCharByPeriod.dta, replace


*** Formatting footnote 
di "Reasons for missing data (not formatted): $footnote_TabCharByPeriod_miss"

* Reword "Missing records"
global footnote_TabCharByPeriod_miss = subinstr(`"${footnote_TabCharByPeriod_miss}"', "Missing records", "had missing records", .)

* Remove last comma in each parentheses and end of sentence
global footnote_TabCharByPeriod_miss = subinstr("$footnote_TabCharByPeriod_miss", ", )", ")", .) 
global footnote_TabCharByPeriod_miss = substr("$footnote_TabCharByPeriod_miss", 1, strrpos("$footnote_TabCharByPeriod_miss", ", ")-1)

* Remove capital letters (except PPGL)
global footnote_TabCharByPeriod_miss = subinstr(lower("$footnote_TabCharByPeriod_miss"), "ppgl", "PPGL", .)

di "Reasons for missing data (formatted): $footnote_TabCharByPeriod_miss"