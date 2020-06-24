***** 3_ImportPopDK.do *****
*** Total population by year
dstpop, clear ///
	fyear(1977) tyear($lastyear) /// 
	area(total)

save data/popDK_total.dta, replace


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

save data/popDK_age.dta, replace

*** Population in DK by period, sex and age
dstpop, clear ///
	fyear(1977) tyear($lastyear) ///
	area(total) ///
	sex ///
	age

recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"

recode year $period10ycat, gen(period) label(period_)
label var period "Period"

bysort period agecat sex: egen poptotal=total(pop)
drop year age pop
rename poptotal pop
duplicates drop

save data/popDK_ageperiod.dta, replace

*** Population in DK by municipality and age
dstpop, clear ///
	fyear(1977) tyear($lastyear) ///
	area(c_kom) ///
	age

recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"

bysort area agecat: egen poptotal=total(pop)
drop year age pop
rename poptotal pop
duplicates drop
save data/popDK_age_municipality.dta

*** Population in Central and Northern Regions by period and age group
dstpop, clear ///
	fyear(1977) tyear($lastyear) ///
	area(c_reg) ///
	age

keep if inlist(area, 81, 82)

recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"
recode year $period10ycat, gen(period) label(period_)
label var period "Period"

bysort period agecat: egen poptotal=total(pop)
drop year age pop area
rename poptotal pop
duplicates drop

save data/popRegion_age_period.dta, replace
