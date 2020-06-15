***** Pheo-inci_CohortAndVars.do *****
use redcap.dta, clear

*** Define cohort
** Study area
recode cohort (1 2 5 = 1 "North/Central Region") (3=2 "Remaining DK"), gen(cohort_simple)

** Index date and year
gen date_index = date_diag if cohort_simple==1
replace date_index = allfirstdate if cohort_simple==2
label var date_index "Index date"
format %d date_index

gen year_index = year(date_index) 
label var year_index "Index year"


** Prevalent cases
gen ppgl_prevalent = 1 if /// 
	cohort_simple==1 & inlist(ppgl, 1, 2) /// Confirmed in health records (in North/central region)
	| cohort_simple==2 & algo_9l==1 & ext_algosample==0 /// Algorithm-positive (in remaining DK)
	| cohort_simple==2 & algo_9l==1 & ext_algosample==1 & ppgl!=0 // Algorithm-positive refuted/excluded in ext.sample
recode ppgl_prevalent (.=0)

* PPGL cases diagnosed 1977-2015 while living in Denmark
	// As prevalent but excluding 3 diagnosed <1977 / outside DK in health records 
gen ppgl_incident = 1 if /// 
	cohort_simple==1 & ppgl==1 & mi(vali_exclude) /// 
	| cohort_simple==2 & algo_9l==1 & ext_algosample==0 ///  
	| cohort_simple==2 & algo_9l==1 & ext_algosample==1 & inlist(ppgl, 0, 2)==0 // 
recode ppgl_incident (.=0)

** Removing non-PPGL patients
keep if inlist(1, ppgl_incident, ppgl_prevalent)
count if ppgl_incident==1 // 588, as reported in validation article (Ebbehoj A 2018, Clin Epidemiol)
drop if year_index>${lastyear} // 21 diagnosed after 2015 removed


order ppgl* year_index cohort cohort_simple, after(d_foddato)


*** Define variables
* Study period (10-year intervals)
recode year_index $period10ycat, gen(period10y) label(period10y_)
label var period10y "Study period 10-year intervals"

* Study period (first 3 periods vs last period)
recode year_index $period2cat, gen(period2cat) label(period2cat_)
label var period2cat "Study period 1977-2006 vs 2007-${lastyear}"

* Age at diagnosis
gen age = (date_index-d_foddato)/365.25
label var age "Age at diagnosis"

* Age categories
recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"

* Mode of discovery groups
recode mod $modcat, gen(modcat) label(modcat_)
label var modcat "Mode of discovery"

* Tumor size
egen tumo_sizemax = rowmax(tumo_size*)
recode tumo_sizemax $sizecat, gen(sizecat) label(sizecat_)
label var tumo_sizemax "Tumor size"
label var sizecat "Tumor size"

* Tumor location
gen tumorcat = 1 if tumo_numb==1 & tumo_loc1==1 // single pheo
recode tumorcat (.=2) if tumo_numb==1 & inlist(tumo_loc1, 2, 3) // single para (2: abdominal, 3: head/neck)
recode tumorcat (.=3) if tumo_numb==2 & tumo_loc1==1 & tumo_loc2==1 // bilat pheo
recode tumorcat (.=4) if tumo_numb==2 & inlist(tumo_loc1, 2, 3) & inlist(tumo_loc2, 2, 3) // multiple para
recode tumorcat (.=.a) if inlist(tumo_numb, 98, 99) // not found or unspecified
label var tumorcat "Tumor location"
label define tumorcat_ ///
	1 "Unilateral pheochromocytoma" ///
	2 "Unilateral paraganglioma" ///
	3 "Bilateral pheochromocytomas" ///
	4 "Multiple paragangliomas" ///
	, replace
label value tumorcat tumorcat_

* Paroxystic symptoms
gen sympcat = 1 if symp_head==1 & symp_sweat==1 & symp_palp==1 // headache, sweating and palpitations

recode sympcat (.=2) if symp_head==1 | symp_head==1 | symp_sweat==1 // 1-2 of headache, sweating or palpitations

recode sympcat (.=3) if inlist(1, symp_flush, symp_white, symp_naus, symp_abdo, symp_dysp,  symp_sync, symp_chest, symp_tremor, symp_sync, symp_light, symp_atta) // 1 or more other paroxcystic symp (flushing, whitening, nausea, abdominal pain, dyspnea, syncope, lightheadedness, chest pain, tremor, or unspecified "attacks")

foreach symp in symp_atta symp_palp symp_head symp_sweat symp_light symp_white symp_flush symp_sync symp_naus symp_chest symp_abdo symp_tremor symp_dysp {
	qui: recode sympcat (.=4) if inlist(`symp', 2, 4, 99) // 2: present but not paroxcystic, 4: Not present, 99: unspecified in records if present
}

recode sympcat (.=.a) if inlist(98, symp_atta, symp_palp, symp_head, symp_sweat, symp_light, symp_white, symp_flush, symp_sync, symp_naus, symp_chest, symp_abdo, symp_tremor, symp_dysp) // Health reocrds not found




*** Remove superfluous/PID variables
drop cpr rec_nr *_comm_* *_comm *_kommentarer /// Sensitive data 
	ppgl exclude algo_* vali_* /// Validation data
	from_* all_* allhighrisk* allfirstdate* /// Details on inclusion criteria 
	pato_* immuno_* datediagnosispato gen_performed gen_mut_* gen_report *_complete // Irrelevant 
	



save ppgl_cohort.dta, replace