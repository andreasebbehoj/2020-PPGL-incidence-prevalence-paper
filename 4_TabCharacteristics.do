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


** Appending results
drop _all
set obs 2
gen var = " "
gen firstcol = "Patients, n " if _n==2
gen seccol = " "
foreach col of local collist {
	di " `col' - `label`col''"
	gen cell_`col' = "`label`col''" if _n==1
	replace cell_`col' = "`coltotal_`col''" if _n==2
}

foreach var in cohort_simple sex agecat modcat sizecat sympcat biocat tumorcat {
	append using `results_`var''
}


** Export to table
replace seccol = subinstr(seccol, "{&ge}", "+", 1)
gen rowname = firstcol
replace rowname = "   " + seccol if mi(rowname)

putdocx clear
putdocx begin
putdocx paragraph
putdocx table tbl1 = data("rowname cell_0 cell_1 cell_2 cell_3 cell_4")
putdocx table tbl1(., .), ${tableoverall}
putdocx table tbl1(., 1/2), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
gen row = _n
levelsof row if !mi(firstcol) & mi(seccol)
putdocx table tbl1(`r(levels)', .), ${tablerows}
putdocx save results/TabCharacteristics, replace

* Modify categorical vars


sss
putdocx text ("Overall crude IR: `ir_mean' (95%CI `ir_lb'-`ir_ub')"), linebreak
putdocx text ("Overall SIR: `sir_mean' (95%CI `sir_lb'-`sir_ub')"), linebreak

putdocx text ("SIR increased from `sirfirst_mean' (95%CI `sirfirst_lb'-`sirfirst_ub') in 1977 to `sirlast_mean' (95%CI `sirlast_lb'-`sirlast_ub') in ${lastyear}."), linebreak
putdocx text ("Fold increase from 1977-${lastyear}: `foldincrease'"), linebreak

putdocx text ("SIR `perlabel1': `sirper1_mean' (95%CI `sirper1_lb'-`sirper1_ub')"), linebreak
putdocx text ("SIR `perlabel2': `sirper2_mean' (95%CI `sirper2_lb'-`sirper2_ub')"), linebreak
putdocx text ("SIR `perlabel3': `sirper3_mean' (95%CI `sirper3_lb'-`sirper3_ub')"), linebreak
putdocx text ("SIR `perlabel4': `sirper4_mean' (95%CI `sirper4_lb'-`sirper4_ub')"), linebreak

putdocx save results/TextSirOverall, replace





** Table (SIR per year)

