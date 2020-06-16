***** Pheo-inci_PopDK.do *****
*** Total population by year
dstpop, clear ///
	fyear(1977) tyear($lastyear) /// 
	area(total)

save popDK_total.dta, replace


*** Population by year and age group
dstpop, clear ///
	fyear(1977) tyear($lastyear) /// 
	area(total) /// 
	age

recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"
bysort year agecat: egen poptotal=total(pop)
drop age pop 
rename poptotal pop
duplicates drop

save popDK_age.dta, replace