***** 3_CohortAndVars.do *****
use data/cohort_alldata.dta, clear


*** Define cohort
** Study area
recode cohort (1 2 5 = 1 "North and Central Region") (3=2 "Remaining DK"), gen(cohort_simple_)
label var cohort_simple "Study area"

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


*** Define study variables
* Study period (10-year intervals)
recode year_index $period10ycat, gen(period10y) label(period10y_)
label var period10y "Period"

* Study period (first 3 periods vs last period)
recode year_index $period2cat, gen(period2cat) label(period2cat_)
label var period2cat "Period"

* Age at diagnosis
gen age = (date_index-d_foddato)/365.25
label var age "Age in years"

* Age categories
recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age at diagnosis"

* Sex
recode sex (0=2)
label define sex_ 1 "Male" 2 "Female" 0 "", modify

* Mode of discovery groups
recode mod $modcat, gen(modcat) label(modcat_)
label var modcat "Mode of discovery"

* Tumor size
egen sizemax = rowmax(tumo_size*)
recode sizemax $sizecat, gen(sizecat) label(sizecat_)
label var sizemax "Size in cm"
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
	.a "Missing" ///
	, replace
label value tumorcat tumorcat_


/* Paroxystic symptoms
Data recorded on
- Classic symptoms: paroxysmal headache, sweating and palpitations
- Other symptoms: flushing, whitening, nausea, abdominal pain, dyspnea, syncope, lightheadedness, chest pain, tremor, or unspecified "attacks"

symp_x:
	1: Present and paroxysmal
	2: Present but not paroxysmal
	3: Present, unspecied if paroxysmal or not (treated as not paroxysmal)
	4: Not present,
	98: Health records missing
	99: Unspecified in records if present (treated as not present)
*/
gen sympcat = 1 if /// classic triad
	symp_head==1 & symp_sweat==1 & symp_palp==1

recode sympcat (.=2) if /// 1-2 classic symp
	symp_head==1 | symp_head==1 | symp_sweat==1

recode sympcat (.=3) if /// other paroxysmal symp
	inlist(1, symp_flush, symp_white, symp_naus, symp_abdo, symp_dysp, symp_sync, symp_chest, symp_tremor, symp_sync, symp_light, symp_atta)

foreach symp in /// no paroxysmal symp
	symp_palp symp_head symp_sweat symp_light symp_white symp_flush ///
	symp_sync symp_naus symp_chest symp_abdo symp_tremor symp_dysp symp_atta {
	qui: recode sympcat (.=4) if inlist(`symp', 2, 4, 99)
}

recode sympcat (.=5) if inlist(98, /// health records not found
	symp_palp, symp_head, symp_sweat, symp_light, symp_white, symp_flush, ///
	symp_sync, symp_naus, symp_chest, symp_abdo, symp_tremor, symp_dysp, symp_atta)

label define sympcat_ ///
	1 "Classic triad" ///
	2 "1-2 classic symptoms" ///
	3 "Other paroxysmal symptoms" ///
	4 "No paroxysmal symptoms" ///
	5 "Unknown" ///
	, replace
label value sympcat sympcat_
label variable sympcat "Symptoms at diagnosis"

* Years of symptoms before diagnosis
gen sympyears = (date_index-date_symp)/365.25
label var sympyears "Symptom duration in years"

* Hypertension
recode symp_hyper ${htncat}, gen(htncat) label(htncat_)
label var htncat "Hypertension at diagnosis"

* Biochemical profile
recode tumo_bioc ${biocat}, gen(biocat) label(biocat_)
label var biocat "Biochemical profile"

* Biochemical elevation
egen biomax = rowmax(tumo_bioc_ne tumo_bioc_e tumo_bioc_uns)
label var biomax "Fold increase above upper normal range"

* Genetic disposition
recode gen_synd	(1 2 3 4 56 7 8 9 10 11 20 30 39 = 1 "Hereditary PPGL") /// confirmed clinically or genetically
				(44=2 "Negative genetic tests") /// No known syndrome/mutation (both tested and non-tested)
				(12345=3 "Never genetically tested") /// empty value to create label
				(98=4 "Not found") /// 
				, gen(gencat) label(gencat_)
recode gencat (2=3) if obta_gene==2 // Recode for those never tested
label var gencat "Hereditary PPGL"

*** Restrict to PPGL patients
keep if inlist(1, ppgl_incident, ppgl_prevalent)

count if ppgl_incident==1
local incitotal=`r(N)'
count if year_index>${lastyear} // Patients diagnosed after 2015 removed
local afterlastyear=`r(N)'

drop if year_index>${lastyear}

count if ppgl_incident==1
local incifinal=`r(N)'
count if ppgl_prevalent==1
local prevfinal=`r(N)'

*** Remove superfluous variables
drop tumo_numb tumo_loc* tumo_size* tumo_late* tumo_bioc symp_* /// Aggregated in code above
	ppgl cohort exclude algo_* vali_* ext_algosample /// Validation data
	from_* all_* allhighrisk* allfirstdate* /// Details on inclusion criteria
	pato_* immuno_* datediagnosispato gen_performed gen_mut_* gen_report *_complete obta_* regeval_surg // Irrelevant for study


*** Save data
order cohort_simple ppgl* include_reg year_index period* age* sex mod* size* symp* bio* tumo*

** Report
putdocx clear
putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("Patient flow")
putdocx paragraph
putdocx text ("Total PPGL cohort from 1977-2016 was `incitotal' (Ebbehoj A 2018, Clin Epidemiol). ")
putdocx text ("We excluded `afterlastyear' patients diagnosed after ${lastyear}. ")
putdocx text ("Final cohort in this study was `incitotal' incident cases of PPGL and `prevfinal' prevalent cases. "), linebreak
putdocx save results/TextPatientFlow, replace

** With PID
save data/cohort_pid.dta, replace


** Without PID
drop cpr id rec_nr *_comm_* *_comm d_foddato c_status d_status /// Sensitive data
	date_symp date_index date_diag date_recu* date_surg* // Aggregated in code above

save data/cohort_ppgl.dta, replace
