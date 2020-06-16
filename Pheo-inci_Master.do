***** pheo-inci_Master.do *****
/*
This do file runs the analyzing for the paper on Incidence and Prevalence of PPGL by Ebbehoj et al, 2020. 

The do-file is split in four sections: 
1) Stata setup
2) Define study variables 
3) Import and prepare data
4) Analysis
*/


***** 1) STATA SETUP
version 16
set more off
clear
file close _all

/*** Install necessary packages
net install github, from("https://haghish.github.io/github/")
github install andreasebbehoj/dstpop
net install mat2txt.pkg
tab2xl2, from(https://github.com/leonardoshibata/tab2xl2/blob/master/) replace
*/



***** 2) DEFINE STUDY VARIABLES
* End of study period
global lastyear = 2015

* Study period (10-year intervals)
global period10ycat = 	`"(1977/1986=1 "1977-1986")"' ///
						+ `" (1987/1996=2 "1987-1996")"' ///
						+ `" (1997/2006=3 "1997-2006")"' ///
						+ `" (2007/${lastyear}=4 "2007-${lastyear}")"' //

* Study period (first 3 periods vs last period)
global period2cat =		`"(1977/2006=1 "1977-2006")"' ///
						+ `" (2007/${lastyear}=2 "2007-${lastyear}")"' //

* Age categories
global agecat = `"(0/24.999=1 "<25")"' ///
				+ `" (25/49.999=2 "25-49")"' ///
				+ `" (50/74.999=3 "50-74")"' ///
				+ `" (75/100=4 ">75")"'

* Mode of discovery grouping
numlabel mod_, add
tab mod
global modcat = `"(1 3 4=1 "Symptoms")"' ///
				+ `" (2=2 "Hypertension")"' ///
				+ `" (20=3 "Adrenal incidentaloma")"' ///
				+ `" (30 31=4 "Cancer imaging")"' ///
				+ `" (40 41=5 "Genetic")"' ///
				+ `" (50=6 "Autopsy")"' ///
				+ `" (60 61 62 63 64 66=7 "Other")"' ///
				+ `" (98 99=8 "Unknown")"' //
				
* Tumor size (largest diameter)
global sizecat = `"(0/1.999=1 "<2 cm")"' ///
					+ `" (2/3.999=2 "2-3.9 cm")"' ///
					+ `" (4/5.999=3 "4-5.9 cm")"' ///
					+ `" (6/7.999=4 "6-7.9 cm")"' ///
					+ `" (8/9.999=5 "8-9.9 cm")"' ///
					+ `" (10/50=6 ">10 cm")"' ///
					+`" (.=.a "Missing")"'

* Biochemical profile
global biocat = `"(1=1 "NE only")"' ///
					+ `" (2=2 "E only")"' ///
					+ `" (3=3 "Both NE and E")"' ///
					+ `" (98=.a "Not found")"' ///
					+ `" (4=.b "Unspecified (NE+E measured together)")"' ///
					+ `" (7=.c "Never tested")"' //

/* Tumor location
tumorcat: 
	1: single pheo
	2: single para
	3: bilat pheo
	4: multiple para
	.a: missing
Defined in Pheo-inci_CohortAndVars.do */


/* Symptoms
sympcat:
	1: all three of classic symptoms 
	2: 1-2 of classic symptoms
	3: 1 or more other paroxysmal symptom
	4: no paroxysmal symptoms described 
	.a: Missing
Defined in Pheo-inci_CohortAndVars.do */





***** 3) IMPORT AND PREPARE DATA
/*
This section: 
1) Import data on Danish population from Statistics Denmark
2) Define European Standard population
3) Import clinical data on PPGL patients from a REDCap database
4) Generate study variables and restrict to final PPGL cohort
*/

** Danish population
do Pheo-inci_PopDK.do

** EU standard population
do Pheo-inci_PopEU.do

** Import PPGL patients from ReDCap
do Pheo-inci_ImportRedcap.do 

** Generate study variables and restrict to cohort
do Pheo-inci_CohortAndVars.do




***** 4) Analysis
/*
This section: 
1) Makes calculations for text 
2) Export tables 
3) Export graphs
4) Combines results in a single report
*/

** Table - Baseline


** Figure - SIR overall


** Figure - SIR by MoD


** Combine report


window manage close graph _all