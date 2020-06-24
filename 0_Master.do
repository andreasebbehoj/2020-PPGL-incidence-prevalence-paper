***** 0_Master.do *****
/*
This do file runs the analysis for the paper on Incidence and Prevalence of PPGL by Ebbehoj et al, 2020. 

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
cd "U:\2020-PPGL-incidence-prevalence-paper"
capture: mkdir data
capture: mkdir results

/*** Install necessary packages
net install github, from("https://haghish.github.io/github/")
github install andreasebbehoj/dstpop
ssc install grstyle, replace
ssc install palettes, replace
ssc install colrspace, replace
ssc install spmap, replace
ssc install shp2dta, replace
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
global agecat = `"(0/24.999=1 "<25 years")"' ///
				+ `" (25/49.999=2 "25-49 years")"' ///
				+ `" (50/74.999=3 "50-74 years")"' ///
				+ `" (75/100=4 "{&ge}75 years")"'

* Mode of discovery grouping
global modcat = `"(1 3 4=1 "Symptoms")"' ///
				+ `" (2=2 "Hypertension")"' ///
				+ `" (20=3 "Adrenal incidentaloma")"' ///
				+ `" (30 31=4 "Cancer imaging")"' ///
				+ `" (40 41=5 "Genetic")"' ///
				+ `" (50=6 "Autopsy")"' ///
				+ `" (60 61 62 63 64 66=7 "Other")"' ///
				+ `" (98 99=8 "Unknown")"' //
				
* Tumor size (largest diameter)
global sizecat = `"(0/3.999=1 "<4 cm")"' ///
					+ `" (4/7.999=2 "4-7.9 cm")"' ///
					+ `" (8/50=3 "{&ge}8 cm")"' ///
					+`" (.=4 "Missing")"'

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
- Import data on Danish population from Statistics Denmark
- Define European Standard population
- Import clinical data on PPGL patients from a REDCap database
- Generate study variables and restrict to final PPGL cohort
*/

** Danish population
do 3_ImportPopDK.do

** EU standard population
do 3_ImportPopEU.do

** Import PPGL patients from ReDCap
do 3_ImportRedcap.do 

** Generate study variables and restrict to cohort
do 3_CohortAndVars.do




***** 4) Analysis
/*
This section: 
- Defines common settings for figures and tables
- Makes calculations for text 
- Export tables 
- Export graphs
- Generate supplementary results
- Combines results in a single report
*/

** Common settings for all figures
do 4_FigTabLayout.do

** Baseline


** SIR overall
do 4_SirOverall.do

** SIR by municipality
do 4_SirByMunicipality.do

** IR by age and sex
do 4_IrByAgeSex.do

** SIR by MoD
do 4_SirByMod.do

** SIR by symptoms
do 4_SirBySymp.do

** SIR by tumor size
do 4_SirBySize.do

** Prevalence
do 4_Prev.do

** Combine report
do 4_Report.do


file close _all
window manage close graph _all