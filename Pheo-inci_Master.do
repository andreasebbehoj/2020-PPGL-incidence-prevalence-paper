***** pheo-inci_Master.do *****
/*
Some text

*/

/*** Install necessary packages
** For importing Danish population
net install github, from("https://haghish.github.io/github/")
github install andreasebbehoj/dstpop

** For exporting tables
net install mat2txt.pkg
tab2xl2, from(https://github.com/leonardoshibata/tab2xl2/blob/master/) replace
*/


version 16
set more off
clear
file close _all


*** Import data on cohort
	// Import ppgl cohort from REDCap database
	// Stored in ppgl_incident.dta and ppgl_prevalent.dta
do Pheo-inci_ImportRedcap.do


*** Prepare data


*** Figure 1


*** Figure 2


*** Table 1


*****
window manage close graph _all
