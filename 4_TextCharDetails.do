***** 4_TextPatCharDetails.do *****
use data/cohort_ppgl.dta, clear

keep if ppgl_incident==1 & cohort_simple==1


*** Report
putdocx clear
putdocx begin

* Count for table foot notes 
count if !mi(modcat)
global Nmod = `r(N)'

count if mi(modcat)
global Nmodmiss = `r(N)'


** Reasons for no surgery
putdocx paragraph, style(Heading2)
putdocx text ("Reasons for no radical surgery")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)

local var = "surg_reason"
qui: levelsof `var'

foreach grp in `r(levels)' {
	local grplabel : label `var'_ `grp'
	qui: count if `var'==`grp'
	putdocx text ("`r(N)' `grplabel'"), linebreak
}


** Diagnosis before surgery
count if modcat!=3 & !mi(modcat) // not autopsied
local Ndiagalive = `r(N)'
count if modcat==3 // autopsied
local Nautopsy = `r(N)'

count if surg_resec==1 & modcat!=3 & !mi(modcat) // Underwent surgery
local Nsurgery = `r(N)'
count if surg_resec==7 & modcat!=3 & !mi(modcat) // No surgery
local Nnosurgery = `r(N)'

count if surgcat==1 // Diagnosed before surgery
local Npreopdiag = `r(N)'

count if surgcat==2  // Diagnosed after surgery
local Npostopdiag = `r(N)'
local Ppostopdiag = string(round(100*`Npostopdiag'/`Nsurgery', 0.1), "%3.1f")

putdocx paragraph, style(Heading2)
putdocx text ("Diagnosis before surgery")
putdocx paragraph
putdocx text ("Out of `Ndiagalive' patients who were diagnosed while alive ($Ncrnr patients minus `Nautopsy' diagnosed at autopsy and $Nmodmiss with missing records before diagnosis), `Nsurgery' were operated and `Nnosurgery' were not. Of the `Nsurgery' undergoing surgery, `Npreopdiag' were diagnosed before surgery and `Npostopdiag' (`Ppostopdiag'%) were diagnosed with PPGL AFTER resection of PPGL.")


** Perisurgical mortality
tab surgcat surg_perimort, mi
count if surg_perimort==1 & surgcat==1
local Npreopdiagmort = `r(N)'
local Ppreopdiagmort = string(round(100*`Npreopdiagmort'/`Npreopdiag', 0.1), "%3.1f")

count if surg_perimort==1 & surgcat==2
local Npostopdiagmort = `r(N)'
local Ppostopdiagmort = string(round(100*`Npostopdiagmort'/`Npostopdiag', 0.1), "%3.1f")

putdocx paragraph, style(Heading2)
putdocx text ("Peri-operative mortality")
putdocx paragraph
putdocx text ("Of `Npreopdiag' diagnosed before surgery, `Npreopdiagmort' (`Ppreopdiagmort' %) died up within 30 days of surgery. Of `Npostopdiag' NOT diagnosed before surgery, `Npostopdiagmort' (`Ppostopdiagmort' %) died up within 30 days of surgery. ")


** Mets and recurrence 
putdocx paragraph, style(Heading2)
putdocx text ("Metastases and recurrence")

* Mets at time of diagnosis
count if tumo_meta==1 
local Nmets = `r(N)'
local Pmets = string(round(100*`Nmets'/$Ncrnr, 0.1), "%3.1f")
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
	local Precur = string(round(100*`Nrecur'/$Ncrnr, 0.1), "%3.1f")
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

