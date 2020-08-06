***** 4_TabMod.do *****
use data/cohort_ppgl.dta, clear
merge 1:1 id using data/cohort_pid, assert(match) nolabel nogen noreport ///
		keepusing(mod_comm mod_comm_cod) // Add comments on special cases of MoD

keep if ppgl_incident==1
keep if cohort_simple==1

tab modcat


*** Generate descriptive text 
	// This section is partially excluded from log to hide sensitive data
gen mod_textdetails = ""
label list mod_

** Symptoms
capture: log off
slist id mod_special mod_comm if mod==1
capture: log on

replace mod_textdetails = "Diagnosed after evaluation for paroxysmal symptoms caused by catecholamine-excess, including palpitations, headache, diaphoresis, pallor, flushing, chest pain, tremor, and unspecified spells." if mod==1


** Secondary HTN
capture: log off
slist id mod_special mod_comm if mod==2 
capture: log on

replace mod_textdetails = "Diagnosed after evaluation for secondary hypertension caused by catecholamine-excess." if mod==2 & mod_special!=1

replace mod_textdetails = "Evaluation for secondary hypertension caused by tumor compressing renal artery. Tumor removed on suspicion of renal cancer with labile peri-operative BP and post-operative diagnosis of pheochromocytoma." if id==1783


** Pressor-response pregnancy/birth
capture: log off
slist id mod_special mod_comm if mod==3
capture: log on

replace mod_textdetails = "Diagnosed after pressor-response during pregnancy/birth" if mod==3


** Pressor-response surgery/anesthesia
capture: log off
slist id mod_special mod_comm if mod==4
capture: log on

replace mod_textdetails = "Diagnosed after pressor-response during surgery/anesthesia unrelated to PPGL or adrenals." if mod==4 & inlist(id, 625, 854, 1507, 3242)

replace mod_textdetails = "Diagnosed after pressor-response occurring during the day after minor surgery." if id==1816
replace mod_textdetails = "Diagnosed after pressor-response during aspiration of a suspected renal cyst, later confirmed to be a pheochromocytoma." if id==975


** Adrenal Incidentaloma
capture: log off
slist id mod_special mod_biopsy mod_preopdiag mod_comm if mod==20 & mod_special==1
capture: log on

* "Normal" incidentalomas
qui: count if mod==20 & mod_special!=1 & mod_imagemodality==1
local no_ct = `r(N)'
qui: count if mod==20 & mod_special!=1 & mod_imagemodality==2
local no_us = `r(N)'
qui: count if mod==20 & mod_special!=1 & mod_imagemodality==3
local no_mri = `r(N)'
qui: count if mod==20 & mod_special!=1 & mod_imagemodality==4
local no_other = `r(N)'

replace mod_textdetails = "Diagnosed after evaluation for adrenal incidentaloma found on CT (n=`no_ct'), US (n=`no_us'), MRI (n=`no_mri'), or other imaging (n=`no_other')" if mod==20 & mod_special!=1

* Incidentalomas postOP diagnosed as pheo
replace mod_textdetails = "Diagnosed after surgical removal of cancer-suspicious adrenal incidentaloma. One patient had normal peri-operative BP and two had very labile BP, one of whom died of bleeding complications immediately after surgery." if mod==20 & mod_special==1 & mod_preopdiag==0

* FNA/Biopsied incidentalomas  (diagnosed before surgery / never operated)
replace mod_textdetails = "Diagnosed after FNA and/or biopsy of adrenal incidentaloma. Incidentalomas found on CT" if mod==20 & mod_special==1 & inlist(mod_biopsy, 1, 2, 3)

* Initially silent AI-pheo
replace mod_textdetails = "Patient diagnosed with 23 mm adrenal incidentaloma with unenhanced CT attenuation of 30 Hounsfield units. Followed for three years without any symptoms, growth or biochemical evidence of catecholamine-excess. Re-evaluation six years later due to paroxysmal symptoms showed tumor growth to 48 mm and catecholamine-excess." if id==2846


** Cancer staging
capture: log off
slist id mod_special mod_biopsy mod_preopdiag mod_comm if mod==30 
capture: log on

replace mod_textdetails = "Diagnosed during staging of other cancer. Two patients were operated for their other cancers before work-up for PPGL was conducted." if mod==30 & mod_special==0 | mod==30 & mod_special==1 & mod_biopsy==0 & mod_preopdiag==1

replace mod_textdetails = "Diagnosed after FNA of suspected adrenal metastasis." if mod==30 & mod_special==1 & mod_biopsy==1 

replace mod_textdetails = "Diagnosed after surgical removal of suspected adrenal metastasis. Two patients were operated without any biochemical work-up and one patient had elevated catecholamines but was operated before test results were seen." if mod==30 & mod_special==1 & mod_preopdiag==0


** Cancer FU
capture: log off
slist id mod_special mod_biopsy mod_preopdiag mod_comm if mod==31
capture: log on

replace mod_textdetails = "Diagnosed during follow-up of previous cancer." if mod==31 & mod_special==0 

replace mod_textdetails = "Diagnosed after failed FNA and surgical removal of suspected adrenal metastasis." if mod==31 & mod_special==1 & mod_biopsy==1 & mod_preopdiag==0


** Evaluation/control for syndrome or mutation
capture: log off
slist id mod_special mod_biopsy mod_preopdiag mod_comm if mod==40
capture: log on

* List of genes/syndromes
local textgenes = ""
qui: levelsof gen_synd if mod==40, local(genes)
foreach gene of local genes {
	local label : label gen_synd_ `gene'
	qui: count if gen_synd==`gene' & mod==40
	local textgenes = itrim("`textgenes'`label' (n=`r(N)'), ")
}
local textgenes = reverse(subinstr(subinstr(reverse("`textgenes'"), ",", "", 1)), ",", "dna ,", 1)
di "`textgenes'"

replace mod_textdetails = "Diagnosed during work-up or regular control for predisposing mutation or syndrome in `textgenes'." if mod==40


** Familial disposition
capture: log off
slist id mod_special mod_biopsy mod_preopdiag mod_comm if mod==41
capture: log on

* List of genes/syndromes
local textgenes = ""
qui: levelsof gen_synd if mod==41, local(genes)
foreach gene of local genes {
	local label : label gen_synd_ `gene'
	qui: count if gen_synd==`gene' & mod==41
	local textgenes = itrim("`textgenes'`label' (n=`r(N)'), ")
}
local textgenes = reverse(subinstr(subinstr(reverse("`textgenes'"), ",", "", 1)), ",", "dna ,", 1)
di "`textgenes'"

replace mod_textdetails = "Diagnosed due to family member diagnosed with predisposing mutation or syndrome in `textgenes'." if mod==41


** Autopsy
capture: log off
slist id mod_special mod_comm_cod mod_comm if mod==50
capture: log on

qui: count if mod==50 & mod_cod==1
local no_codprim = `r(N)'
qui: count if mod==50 & mod_cod==2
local no_codcont = `r(N)'
qui: count if mod==50 & mod_cod==3
local no_codinci = `r(N)'

replace mod_textdetails = "Diagnosed at autopsy with PPGL considered to be the primary cause of death (n=`no_codprim'), a contributing cause of death (n=`no_codcont'), or a incidental or insignificant finding (n=`no_codinci')." if mod==50


** Other
capture: log off
slist id mod mod_special mod_biopsy mod_preopdiag mod_comm if inrange(mod, 60, 69)
capture: log on

* Bsymp
replace mod_textdetails = "Evaluated for B-symptoms (weight loss, fatigue, unexplained fever, and excessive sweating). One patient was diagnosed with benign paraganglioma (causing activation of brown adipose tissue and excessive sweating), one was patient diagnosed with paraganglioma with central necrosis (causing fever), one patient was diagnosed with metastatic pheochromocytoma, and two patients were operated on suspicion of renal or pancreatic cancer, which turned out to be benign pheochromocytomas." if mod==60

* Abdominal mass
replace mod_textdetails = "Evaluated for large palpable abdominal mass. Patient was operated on suspicion of unknown cancer, which turned out to be a giant pheochromocytoma (approximate 30 cm). Patient was later diagnosed with multiple metastases." if mod==61

* Acute abdomen caused by pheo
replace mod_textdetails = "Evaluated for acute abdominal pain. Abdominal pain was eventually attributed to ruptured pheochromocytoma (n=1), pheochromocytoma with hemorhage and necrosis (n=1), necrotic intestines due to catecholamine storm (n=1), widespread metastatic pheochromocytoma (n=1), and paroxysmal symptoms of catecholamine-excess (n=1)." if mod==62

* Ectopic ACTH
replace mod_textdetails = "Evaluated for symptoms of cortisol-excess and diagnosed with ACTH-producing pheochromocytoma." if mod==63

* Abdominal paraganglioma "incidentaloma"
replace mod_textdetails = "Diagnosed due to an incidentally found peri-adrenal paraganglioma." if mod==64

* Heart failure
replace mod_textdetails = "Evaluated for acute myocardial infarction and heart failure. Chest x-ray show impression of large tumor, which is biopsied twice and removed of suspicion of renal cancer. Pathologist diagnose a benign pheochromocytoma. Heart failure is eventually attributed to Takutsubo myopathy in combination with myocardial infarction." if mod==66

** Not found
replace mod_textdetails = "Health records missing from time before diagnosis." if mod==98



*** Export results to table
assert !mi(mod_textdetails)

gen n=1
collapse (sum) n, by(modcat mod_textdetails)
gsort +modcat -n


*** Open excel file
putexcel clear
putexcel set results/TabModDetails.xlsx, replace

local row = 1
putexcel A`row'="Mode of Discovery" B`row'="No. of Patients" C`row'="Details on PPGL diagnosis"



levelsof modcat, local(modcats)
foreach grp of local modcats {
	local label`grp' : label modcat_ `grp'
	qui: count if modcat==`grp'
	local no`grp' = `r(N)'
	di "`grp' - `label`grp'' N=`no`grp''"
	tab mod mod_special if modcat==`grp' //& mod_special!=1
	
	capture: log off // Hide sensitive notes
	slist id mod mod_comm if modcat==`grp' & mod_special==1 
	capture: log on
}



putexcel save