***** 4_TextPatCharDetails.do *****
use data/cohort_ppgl.dta, clear

keep if ppgl_incident==1 & cohort_simple==1
qui: count
local Ntotal = `r(N)'


*** Report
putdocx clear
putdocx begin


** Reasons for no surgery
putdocx paragraph, style(Heading2)
putdocx text ("Reasons for no radical surgery")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)

local var = "surg_reason"
tab `var'
qui: levelsof `var'

foreach grp in `r(levels)' {
	local grplabel : label `var'_ `grp'
	qui: count if `var'==`grp'
	putdocx text ("`r(N)' `grplabel'"), linebreak
}


** Mets and recurrence 
putdocx paragraph, style(Heading2)
putdocx text ("Metastases and recurrence")

* Mets at time of diagnosis
count if tumo_meta==1 
local Nmets = `r(N)'
local Pmets = string(round(100*`Nmets'/`Ntotal', 0.1), "%3.1f")
putdocx paragraph
putdocx text ("`Nmets' (`Pmets'%) had confirmed metastases at time of diagnosis")

* Recurrences
putdocx paragraph
putdocx text ("All combinations of recurrence (metastases, new primary tumor, and local recurrence):")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)

egen recu_all = group(recu_mets recu_prim recu_local), missing label lname(recu_all_)

local var = "recu_all"
qui: levelsof `var'
foreach grp in `r(levels)' {
	local grplabel : label `var'_ `grp'
	qui: count if `var'==`grp'
	local Nrecur = `r(N)'
	local Precur = string(round(100*`Nrecur'/`Ntotal', 0.1), "%3.1f")
	putdocx text ("`Nrecur' (`Precur'%) `grplabel'"), linebreak
}

* Time to recurrence
putdocx paragraph
putdocx text ("Time from surgery to recurrence:")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)
foreach var in any mets prim local {
	qui: gen years = recu_`var'_age-age
	qui: su years, detail
	local Trecur = string(`r(p50)', "%3.1f") + " years (range " ///
				+ string(`r(min)', "%3.1f") + "-" ///
				+ string(`r(max)', "%3.1f") + ")" //
	drop years
	putdocx text ("`Trecur' `var'"), linebreak
}


** Genetic 
putdocx paragraph, style(Heading2)
putdocx text ("Genetic details")
putdocx paragraph
putdocx text ("Mutations and syndromes included:")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)

local var = "gen_synd"
levelsof `var' if gencat==1 
foreach grp in `r(levels)' {
	local grplabel : label `var'_ `grp'
	qui: count if `var'==`grp'
	putdocx text ("`r(N)' `grplabel'"), linebreak
}


putdocx save results/TextPatChar, replace

