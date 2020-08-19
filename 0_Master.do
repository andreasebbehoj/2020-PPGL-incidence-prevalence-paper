***** 0_Master.do *****
/*
This do file runs the analysis for the paper on Incidence and Prevalence of PPGL by Ebbehoj et al, 2020.

The do-file is split in four sections:
1) Stata setup
2) Define study variables
3) Import and prepare data
4) Analysis
5) Combine report
*/


***** 1) STATA SETUP
version 16
set more off
clear
file close _all
cd "E:\2020-PPGL-incidence-prevalence-paper"
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

/* Arrows with diagnostic changes in study period
global arrows =  `""1996 National coverage of Pathology Registry" "' ///
				+ `""2002 AI guideline (NIH)" "' ///
				+ `""2007 Fast-track cancer diagnosis introduced in Denmark" "' ///
				+ `""2009 AI guideline (AACE) and p-Met introduced in Denmark" "' ///
				+ `""2011 AI guideline (AME)" "' ///
				+ `""2012 AI guideline (Danish)" "' ///
				+ `""2014 PPGL guidelines (Danish and ECE)" "' //
*/

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
global modcat = `"(1=1 "Paroxysmal symptoms")"' ///
				+ `" (2 3 4=2 "Hypertension")"' ///
				+ `" (20=3 "Adrenal incidentaloma")"' ///
				+ `" (30 31=4 "Cancer imaging")"' ///
				+ `" (40 41=5 "Genetic")"' ///
				+ `" (50=6 "Autopsy")"' ///
				+ `" (60 61 62 63 64 66=7 "Other")"' ///
				+ `" (98 99=8 "Not found")"' //

* Tumor size (largest diameter)
global sizecat = `"(0/3.999=1 "<4 cm")"' ///
					+ `" (4/7.999=2 "4-7.9 cm")"' ///
					+ `" (8/50=3 "{&ge}8 cm")"' ///
					+`" (.=4 "Not found")"'

* Biochemical profile
global biocat = `"(1=1 "NE only")"' ///
					+ `" (2=2 "E only")"' ///
					+ `" (3=3 "Both NE and E")"' ///
					+ `" (4=4 "Unspecified (NE+E measured together)")"' ///
					+ `" (7=5 "Never tested")"' ///
					+ `" (98=6 "Not found")"' //

* Hypertension
global htncat = `"(1=1 "Labile hypertension")"' ///
					+ `" (2 3=2 "Stable hypertension")"' ///
					+ `" (4 99=3 "No hypertension")"' ///
					+ `" (98=4 "Not found")"' //

/* Genetic disposition
gencat: 
	Defined in 3_CohortAndVars.do

* Tumor location
tumorcat:
	Defined in 3_CohortAndVars.do

* Symptoms
sympcat:
	Defined in 3_CohortAndVars.do 
*/





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
*/

** Common settings for all figures
do 4_FigTabLayout.do

** Patient Characteristics by period
do 4_TabCharByPeriod.do

** Patient Characteristics by MoD
do 4_TabCharByMod.do

** MoD details
do 4_TabModDetails.do

** SIR overall
do 4_SirOverall.do

** SIR by year
do 4_SirByYear.do

** SIR by region
do 4_SirByRegion.do

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






***** 5) Report
/*
This section:
- Add headers and footnotes to graphs and tables
- Combine all documents into FigTablesCombined and ReportCombined
*/
do 5_Report.do


file close _all
window manage close graph _all
