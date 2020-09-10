***** 0_Master.do *****
/*
This do file runs the analysis for the paper on Incidence and Prevalence of PPGL by Ebbehoj et al, 2020.

The do-file is split in four sections:
1) Stata setup
2) Import patient data and define study variables
3) Import and prepare other data (population data)
4) Analysis
5) Combine report
*/


***** 1) STATA SETUP
version 16
set more off
clear
file close _all
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
ssc install asdoc, replace
*/



***** 2) PREPARE PATIENT DATA
/*
This section:
- Import clinical data on PPGL patients from a REDCap database
- Define final PPGL cohort and generate study variables for later analyses
*/

do 2_ImportRedcap.do

do 2_CohortAndVars.do



***** 3) PREPARE OTHER DATA
/*
This section:
- Import data on Danish population from Statistics Denmark
- Define European Standard population
*/

do 3_ImportPopDK.do

do 3_ImportPopEU.do



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


** Patient Characteristics 
do 4_TabCharByPeriod.do // by period
do 4_TabCharByMod.do // by MoD
do 4_TextCharDetails.do // details for text
do 4_AgeByMod.do // Age histogram overall and by mod

** MoD details
do 4_TabModDetails.do


** Standardized incidence rates
do 4_SirOverall.do // average and details for text

do 4_SirByYear.do // graph by year
do 4_SirByRegion.do // graph by region and period 

do 4_SirByMod.do // graph by mode of discovery and period
do 4_SirBySymp.do // graph by symptoms and period
do 4_SirBySize.do // graph by size and period

do 4_SirByMunicipality.do // heatmap of Denmark by municipality


** Crude incidence rates
do 4_IrByAgeSex.do // graph by age/sex and period


** Prevalence
do 4_Prev.do // graph by year and details for text




***** 5) Report
/*
This section:
- Add headers and footnotes to graphs and tables
- Combine all documents into FigTablesCombined and ReportCombined
*/
do 5_Report.do


file close _all
window manage close graph _all
