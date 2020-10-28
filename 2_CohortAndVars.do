***** 3_CohortAndVars.do *****
use data/cohort_alldata.dta, clear


*** Define cohort
** Define important criteria
* End of study period
global lastyear = 2015


* Study period (10-year intervals)
global period10ycat = 	`"(1977/1986=1 "1977-1986")"' ///
						+ `" (1987/1996=2 "1987-1996")"' ///
						+ `" (1997/2006=3 "1997-2006")"' ///
						+ `" (2007/${lastyear}=4 "2007-${lastyear}")"' //

* Age categories
global agecat = `"(0/24.999=1 "<25 years")"' ///
				+ `" (25/49.999=2 "25-49 years")"' ///
				+ `" (50/74.999=3 "50-74 years")"' ///
				+ `" (75/100=4 "{&ge}75 years")"'


** Study area
recode cohort (1 2 5 = 1 "North and Central Region") (3=2 "Remaining Danish regions"), gen(cohort_simple) label(cohort_simple_)
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

* Age at diagnosis
gen age = (date_index-d_foddato)/365.25
label var age "Age in years"

* Age categories
recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age at diagnosis"

* Age at surgery
gen age_surg = (date_surg-d_foddato)/365.25
label var age "Age at time of surgery"

* Sex
recode sex (0=2)
label define sex_ 1 "Male" 2 "Female" 0 "", modify

* Mode of discovery categories
label list mod_
recode mod ///
	(1=1 "Paroxysmal symptoms") ///
	(2 3 4=2 "Hypertension") ///
	(50=3 "Autopsy") ///
	(40 41=4 "Genetic") ///
	(20=5 "Adrenal incidentaloma") ///
	(30 31=6 "Cancer imaging") ///
	(60/69=7 "Other") ///
	(98 99=.a "Missing records") ///
	, gen(modcat) label(modcat_)
label var modcat "Mode of discovery"

* Tumor size
egen sizemax = rowmax(tumo_size*)
recode sizemax ///
	(0/3.999=3 "<4 cm") ///
	(4/7.999=2 "4-7.9 cm") ///
	(8/50=1 "{&ge}8 cm") ///
	(.=.a "Missing records") ///
	, gen(sizecat) label(sizecat_)
label var sizemax "Size in cm"
label var sizecat "Tumor size"

* Tumor location
gen tumorcat = 1 if tumo_numb==1 & tumo_loc1==1 // single pheo
recode tumorcat (.=2) if tumo_numb==1 & inlist(tumo_loc1, 2, 3) // single para (2: abdominal, 3: head/neck)
recode tumorcat (.=3) if inrange(tumo_numb, 2, 9) // Multifocal PPGL
recode tumorcat (.=.a) if inlist(tumo_numb, 98, 99) // not found or unspecified
label var tumorcat "Tumor location"
label define tumorcat_ ///
	1 "Unilateral PHEO" ///
	2 "Unilateral PARA" ///
	3 "Multiple PPGL" ///
	.a "had missing records" ///
	, replace
label value tumorcat tumorcat_

* Paroxystic symptoms
/*
Data recorded on
- Classic symptoms: paroxysmal headache, sweating and palpitations
- Other symptoms: flushing, whitening, nausea, abdominal pain, dyspnea, syncope, lightheadedness, chest pain, tremor, or unspecified "attacks"

symp_x:
	1: Present and paroxysmal
	2: Present but not paroxysmal
	3: Present, unspecied if paroxysmal or not (consider not paroxysmal)
	4: Not present,
	98: Health records missing
	99: Unspecified in records if present (consider not present)
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
	qui: recode sympcat (.=4) if inlist(`symp', 2, 3, 4, 99)
}

recode sympcat (.=.a) if inlist(98, /// health records not found
	symp_palp, symp_head, symp_sweat, symp_light, symp_white, symp_flush, ///
	symp_sync, symp_naus, symp_chest, symp_abdo, symp_tremor, symp_dysp, symp_atta)

label define sympcat_ ///
	1 "Classical triad" ///
	2 "1-2 classical symptoms" ///
	3 "Other paroxysmal symptoms" ///
	4 "No paroxysmal symptoms" ///
	.a "Missing records" ///
	, replace
label value sympcat sympcat_
label variable sympcat "Symptoms at diagnosis"

* Years of symptoms before diagnosis
gen sympyears = (date_index-date_symp)/365.25 if inlist(sympcat, 1, 2, 3) // Symptom duration for paroxysmal symp
label var sympyears "Symptom duration in years"

recode sympyears ///
	(0/0.99999=1 "<1 year") ///
	(1/4.99999=2 "1-4.9 years") ///
	(5/max=3 "{&ge}5years") ///
	(12345=.a "had no paroxysmal symptoms") ///
	(12345=.b "had missing records") ///
	, gen(sympycat) label(sympycat_)
label var sympycat "Symptom duration"
recode sympycat (.=.a) if sympcat==4
recode sympycat (.=.b) if cohort_simple==1 & (sympcat==.a | mi(date_symp))

* Hypertension
recode symp_hyper ///
	(1=1 "Labile hypertension") ///
	(2 3=2 "Stable hypertension") ///
	(4 99=3 "No hypertension") ///
	(98=.a "had missing records") ///
	, gen(htncat) label(htncat_)
label var htncat "Hypertension at diagnosis"

* Biochemical profile
recode tumo_bioc ///
	(1=1 "NE only") ///
	(2=2 "E only") ///
	(3=3 "Both NE and E") ///
	(4=.a "had only total catecholamines measured") ///
	(5=4 "Non-functioning") ///
	(7=.b "were never tested") ///
	(98=.c "had missing records") ///
	, gen(biocat) label(biocat_)
label var biocat "Biochemical profile"

* Biochemical elevation
egen biomax = rowmax(tumo_bioc_ne tumo_bioc_e tumo_bioc_uns)
label var biomax "Fold increase above upper normal range"

* Genetic disposition
recode gen_synd	(1 2 3 4 56 7 8 9 10 11 20 30 39 = 1 "Hereditary PPGL") /// confirmed clinically or genetically
				(44=2 "Negative genetic tests") /// No known syndrome/mutation (both tested and non-tested)
				(12345=3 "Never tested") /// empty value to create label
				(98=.a "had missing records") /// 
				, gen(gencat) label(gencat_)
recode gencat (2=3) if obta_gene==2 // Recode for those never tested
label var gencat "Hereditary PPGL"

* PreOP diag
recode mod_preopdiag 	(1=1 "Yes") ///
						(0=2 "No") ///
						(12345=.a "were diagnosed at autopsy") ///
						(12345=.b "were never operated for other reasons") ///
						(98=.c "had missing records") ///
						, gen(surgcat) label(surgcat_)
recode surgcat (.=.a) if surg_reas==1 // Diagnosed at autopsy
recode surgcat (.=.b) if inlist(surg_reas, 2, 3, 4, 5) // All non-operated (except those diagnosed at autopsy)
label var surgcat "PPGL diagnosed before surgery"

* PeriOP death
gen survdays=d_status-date_surg if c_status==90 // days from surgery to death
gen surg_perimort = 1 if survdays<30 & inlist(surgcat, 1, 2)
recode surg_perimort (.=0) if inlist(surgcat, 1, 2)
label var surg_perimort "Peri-surgical mortality (<30 days)"
label define surg_perimort_ 1 "Yes" 0 "No"
label values surg_perimort surg_perimort_

* Recurrence
codebook cour_recu1
local recugrp2 = "mets"
local recugrp3 = "prim"
local recugrp4 = "local"

foreach recu in 2 3 4 { 
	qui: gen recu_`recugrp`recu'' = 1 if inlist(`recu', cour_recu1, cour_recu2, cour_recu3)
	label var recu_`recugrp`recu'' "Recurrence: `recugrp`recu''"
	label define recu_`recugrp`recu''_ 1 "`recugrp`recu''"
	label value recu_`recugrp`recu'' recu_`recugrp`recu''_
	* Age at first recurrence
	qui: gen recu_`recugrp`recu''_age = (date_recu1-d_foddato)/365.25 if cour_recu1==`recu'
	qui: replace recu_`recugrp`recu''_age = (date_recu2-d_foddato)/365.25 if cour_recu2==`recu' & mi(recu_`recugrp`recu''_age)
	qui: replace recu_`recugrp`recu''_age = (date_recu3-d_foddato)/365.25 if cour_recu3==`recu' & mi(recu_`recugrp`recu''_age)
	
	label var recu_`recugrp`recu''_age "Age at recurrence (`recugrp`recu'')"
}
egen recu_any = rowmin(recu_mets recu_prim recu_local)
label var recu_any "Recurrence: any"
egen recu_any_age = rowmin(recu_mets_age recu_prim_age recu_local_age)
label var recu_any_age "Age at recurrence: any"


*** Restrict to PPGL patients
keep if inlist(1, ppgl_incident, ppgl_prevalent)

* Count incident/prevalent for report
count if ppgl_incident==1
local incitotal=`r(N)'
count if year_index>${lastyear} // Patients diagnosed after 2015 removed
local afterlastyear=`r(N)'

drop if year_index>${lastyear}

count if ppgl_incident==1
global Ninci=`r(N)'
count if ppgl_prevalent==1
local Nprev=`r(N)'

count if cohort_simple==1 & ppgl_incident==1 // with clinical data
global Ncrnr = `r(N)'

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
putdocx text ("Final cohort in this study was $Ninci incident cases of PPGL and $Nprev prevalent cases. "), linebreak
putdocx save results/TextPatientFlow, replace

** With PID
save data/cohort_pid.dta, replace


** Without PID
drop cpr rec_nr *_comm_* *_comm d_foddato c_status d_status /// Sensitive data
	date_symp date_index date_diag date_recu* date_surg* // Aggregated in code above

save data/cohort_ppgl.dta, replace
