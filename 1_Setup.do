***** 1_Setup.do *****
version 16
clear all
file close _all

set more off

*** Generate necessary folders
capture: mkdir data
capture: mkdir results


*** Install necessary packages
/*
net install github, from("https://haghish.github.io/github/")
github install andreasebbehoj/dstpop
ssc install grstyle, replace
ssc install palettes, replace
ssc install colrspace, replace
ssc install asdoc, replace
*/


*** Define custom programs

** Program to convert variable+labels from missing to non-missing integers
program define conv_missing
syntax, var(varname) [combmiss(string)]

* Unique values (without unlabeled . missing)
qui: levelsof `var', missing clean local(levels)
local levels = subinstr("`levels'", " . ", " ", 1)

* Label name and summary
local lblname : value label `var'
di "recode: `var'" _col(30) "value label: `lblname'" _col(60) "values: `levels'"

* Loop over values and change missing values to integers
local catno = wordcount("`levels'") // Number of values
local xnew = 1
foreach x of local levels {
	if "`x'"!="`xnew'" {
		local xlabel : label `lblname' `x'
		qui: recode `var' (`x'=`xnew')
		di _col(5) "from `x' to `xnew'" _col(20)  "`xlabel'  (`r(N)' changes made)"
		label define `lblname' `x' "", modify // remove old label
		label define `lblname' `xnew' "`xlabel'", modify // and new label
		
	}
	local xnew = `xnew'+1
}
end