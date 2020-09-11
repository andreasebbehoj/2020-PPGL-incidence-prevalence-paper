***** 3_ImportRedcap.do *****
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
	--form filterLogic="[ppgl]='1' or [ppgl]='2' or [algo_9l]='1'" ///
	`apiurl'


*** Convert to Stata format
import delimited `outfile', ///
	bindquote(strict) /// Fix quotes in text fields
	stringcols(2) // Force CPR var to string
qui: erase `outfile'

qui: ds
local varorder = "`r(varlist)'"
qui: do 2_RedcapCodebook.do, nostop // Redcap Stata export format tool, updated 11-09-2020
order `varorder'


*** Change formats
ds, has(format %d*)
format %tdCCYY-NN-DD `r(varlist)'


*** Save
save data/cohort_alldata.dta, replace
