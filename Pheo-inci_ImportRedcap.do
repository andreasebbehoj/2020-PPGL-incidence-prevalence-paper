***** Article-pheo-inci_ImportRedcap.do *****
clear
file close _all

*** Import secret API key
file open text using APIKEY_redcap.txt, read text
file read text token // Store API key as local 'token'


*** Download file with cURL
local curlpath "C:\Windows\System32\curl.exe"
local outfile "redcap_export.csv"
local apiurl "https://redcap.au.dk/api/"

shell  `curlpath' 	///
	--output `outfile' 		///
	--form token=`token'	///
	--form content=record 	///
	--form format=csv 		///
	--form type=flat 		///
	--form filterLogic="[ppgl]='1' or [algo_9l]='1'" /// 
	`apiurl'


*** Convert to Stata format
import delimited `outfile', ///
	bindquote(strict) /// Fix quotes in text fields
	stringcols(2) // Force CPR var to string
erase `outfile'

qui: ds
local varorder = "`r(varlist)'"
qui: do RedcapCodebook.do, nostop // Redcap Stata export format tool, updated 27-05-2020
order `varorder'


*** Change data formats
qui: ds, has(format %d*)
format %tdCCYY-NN-DD `r(varlist)'


*** Add common variables
recode cohort (1 2 5 = 1 "CRNR") (3=2 "Remaining DK"), gen(cohort_simple)

* Index date and year
gen date_index = date_diag if cohort_simple==1
replace date_index = allfirstdate if cohort_simple==2
format %tdCCYY-NN-DD date_index
label var date_index "Index date (clin diag or algo date)"

gen year_index = year(date_index)
label var year_index "Index year"

* PPGL cases in Denmark (prevalent)
gen ppgl_prevalent = 1 if /// 
	cohort_simple==1 & inlist(ppgl, 1, 2) /// Health record-confirmed from CRNR
	| cohort_simple==2 & algo_9l==1 & ext_algosample==0 /// Algorithm-positive from remaining DK
	| cohort_simple==2 & algo_9l==1 & ext_algosample==1 & ppgl!=0 // Excl records-refuted from external sample
recode ppgl_prevalent (.=0)

* PPGL cases diagnosed 1977-2015 while living in Denmark
gen ppgl_incident = 1 if /// 
	cohort_simple==1 & ppgl==1 & mi(vali_exclude) /// Health record-validated from CRNR
	| cohort_simple==2 & algo_9l==1 & ext_algosample==0 /// Algorithm-positive from remaining DK 
	| cohort_simple==2 & algo_9l==1 & ext_algosample==1 & inlist(ppgl, 0, 2)==0 // Excl records-refuted from external sample
recode ppgl_incident (.=0)


*** Remove superfluous variables
drop cpr rec_nr *_comm_* *_comm *_kommentarer /// Sensitive data 
	ppgl exclude algo_* vali_lab vali_radio vali_path vali_clin vali_eval vali_expert /// Validation
	from_* all_* allhighrisk* allfirstdate* /// Details on inclusion criteria 
	pato_* immuno_* datediagnosispato gen_performed gen_mut_* gen_report *_complete // Irrelevant 
	

*** Restricting to confirmed PPGL
keep if inlist(1, ppgl_incident, ppgl_prevalent)
count if ppgl_incident==1 // 588, as reported in validation article (Ebbehoj A 2018, Clin Epidemiol)
drop if year_index>=2016 // 23 diagnosed in 2016 removed

order ppgl* year_index date_index cohort cohort_simple, after(d_foddato)

save ppgl_prevalent.dta, replace

drop if ppgl_incident==0 // 2 patients diagnosed before 1977, 1 diagnosed outside Denmark
save ppgl_incident.dta, replace