***** 3_ImportPopDK.do *****
*** Total population by year
dstpop, clear ///
	year(1977/$lastyear) /// 
	area(total)

save data/popDK_year.dta, replace


*** Population by year and age group
dstpop, clear ///
	year(1977/$lastyear) ///
	area(total) ///
	age

recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"

bysort year agecat: egen poptotal=total(pop)
drop age pop
rename poptotal pop
duplicates drop

save data/popDK_year_age.dta, replace

*** Population in DK by year/period, age, and sex
dstpop, clear ///
	year(1977/$lastyear) ///
	area(total) ///
	sex ///
	age

* By year
recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"
bysort year agecat sex: egen poptotal=total(pop)
drop age pop
rename poptotal pop
duplicates drop
save data/popDK_year_age_sex.dta, replace

* By period
recode year $period10ycat, gen(period) label(period_)
label var period "Period"

bysort period agecat sex: egen poptotal=total(pop)
drop year pop
rename poptotal pop
duplicates drop

save data/popDK_period_age_sex.dta, replace

*** Population by year, age, and region
dstpop, clear ///
	year(1977/$lastyear) ///
	area(c_reg) ///
	age

recode age $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"

recode area (81 82 = 1) (83 84 85 = 2), gen(cohort_simple)

bysort year cohort_simple agecat: egen poptotal=total(pop)
drop age pop area
rename poptotal pop
duplicates drop
save data/popDK_year_age_region.dta, replace

* Population by period, age, and region
recode year $period10ycat, gen(period) label(period_)
label var period "Period"

bysort cohort_simple agecat period: egen poptotal=total(pop)
drop year pop 
rename poptotal pop
duplicates drop

save data/popDK_period_age_region.dta, replace
