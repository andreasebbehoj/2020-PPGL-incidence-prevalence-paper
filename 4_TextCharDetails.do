***** 4_TextPatCharDetails.do *****
use data/cohort_pid.dta, clear

keep if ppgl_incident==1 & cohort_simple==1


*** Special cases of diagnosis
preserve

putdocx clear
putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("Special cases of diagnosis, post operative diagnosis ect")
putdocx paragraph

order surg_resec surg_reason surg_medalpha mod*
capture: log off
slist modcat mod_special mod_biopsy mod_preopdiag surg_medalpha if mod_special==1, label
capture: log on

** Missing data before diagnosis/surgery 
count if !mi(modcat)
global Nmod = `r(N)'

count if mi(modcat)
global Nmodmiss = `r(N)' // for table footnotes and below
qui: drop if mi(modcat)

putdocx text ("$Nmodmiss had missing records before diagnosis/surgery. ")

** Diagnosed at autopsy
count if modcat==3
local Nautopsy = `r(N)'
local grplabel : label modcat_ 3
putdocx text ("`Nautopsy' diagnosed at `grplabel'"), linebreak
qui: drop if modcat==3


** FNA, biopsy or resection
putdocx paragraph

* Diagnosed alive
count 
local Ndiagalive = `r(N)'

* Overview of FNA, biopsy and/or surgery before PPGL diagnosis
tab mod_biopsy mod_preopdiag if mod_special==1, mi

* FNA/biopsy only
count if inlist(mod_biopsy, 1, 2, 3) & inlist(mod_preopdiag, 1, .) 
local Nneedleonly = `r(N)'

* OP before diagnosis only
count if mod_preopdiag==0 & mod_biopsy==0 
local Npostoponly = `r(N)'

* Both FNA/biopsy and OP before diagnosis
count if inlist(mod_biopsy, 1, 2, 3) & mod_preopdiag==0 // FNA/biopsy and surgery wo diagnosis
local Nneedleandpostop = `r(N)'

* Either FNA/biopsy or OP without diagnosis
count if inlist(mod_biopsy, 1, 2, 3) | mod_preopdiag==0 
local Nneedleorpostop = `r(N)'
local Pneedleorpostop = string(round(100*`Nneedleorpostop'/`Ndiagalive', 0.1), "%3.1f")

putdocx text ("Of the `Ndiagalive' patients diagnosed alive with available data, `Nneedleorpostop' (`Pneedleorpostop'%) patients underwent either FNA or biopsy (n=`Nneedleonly'), surgical resection (n=`Npostoponly'), or both FNA/biopsy and surgical resection (n=`Nneedleandpostop') of the PPGL tumor before being diagnosed with PPGL."), linebreak


** Reasons for no surgery
putdocx paragraph
count if !mi(surg_reason)
local Nnosurgery = `r(N)'
local Pnosurgery = string(round(100*`Nnosurgery'/`Ndiagalive', 0.1), "%3.1f")

putdocx text ("`Nnosurgery' (`Pnosurgery'%) of `Ndiagalive' patients were never operated due to:")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)

global footnote_reasonnosurg = ""

local var = "surg_reason"
qui: levelsof `var'

foreach grp in `r(levels)' {
	local grplabel : label `var'_ `grp'
	qui: count if `var'==`grp'
	putdocx text ("`r(N)' `grplabel'"), linebreak
	global footnote_reasonnosurg = lower("$footnote_reasonnosurg `grplabel' (n=`r(N)'),")
}
di "$footnote_reasonnosurg"
qui: drop if !mi(surg_reason)


** Diagnosis before OP 
putdocx paragraph

* Undergone surgery
count if surg_resec==1
local Nsurgery = `r(N)'
qui: count
assert `r(N)'==`Nsurgery' // Check all remaining were operated

* Diagnosed before OP
count if surg_resec==1 & mod_preopdiag==1
local Nsurgdiag = `r(N)'
local Psurgdiag = string(round(100*`Nsurgdiag'/`Nsurgery', 0.1), "%3.1f")

* Diagnosed after OP
count if surg_resec==1 & mod_preopdiag==0 // diagnosed after OP
local Nsurgnodiag = `r(N)'
local Psurgnodiag = string(round(100*`Nsurgnodiag'/`Nsurgery', 0.1), "%3.1f")

putdocx text ("Of the `Nsurgery' patients who underwent surgery, `Nsurgdiag' (`Psurgdiag' %) patients were diagnosed with PPGL and started on alpha-blockade before surgery, while `Nsurgnodiag' (`Psurgnodiag' %) were diagnosed after surgery. ")


** Peri-operative mortality
tab surgcat surg_perimort, mi

* Diagnosed before OP
count if surg_perimort==1 & mod_preopdiag==1
local Nmortpreop = `r(N)'
local Pmortpreop = string(round(100*`Nmortpreop'/`Nsurgdiag', 0.1), "%3.1f")

* Diagnosed after OP
count if surg_perimort==1 & mod_preopdiag==0
local Nmortpostop = `r(N)'
local Pmortpostop = string(round(100*`Nmortpostop'/`Nsurgnodiag', 0.1), "%3.1f")

putdocx text ("Perioperative mortality (within 30 days of surgery) was `Pmortpreop'% (`Nmortpreop' of `Nsurgdiag' patients) in the first group and `Pmortpostop' % (`Nmortpostop' of `Nsurgnodiag' patients) in the latter."), linebreak


*** Mets and recurrence 
restore
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

* Hereditary syndromes
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

* Genetic tests
putdocx paragraph
putdocx text ("Patients were tested for:")
putdocx paragraph, indent(left, 0.5) spacing(line, 0.2)
foreach gene in RET MEN1 VHL SDH NF {
	qui: count if strpos(gen_tested, "`gene'")
	putdocx text ("`r(N)' `gene'"), linebreak
}

putdocx save results/TextPatChar, replace