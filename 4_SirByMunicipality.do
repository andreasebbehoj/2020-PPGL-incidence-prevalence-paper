***** 4_SirByMunicipality.do *****

*** Prepare map
	// Maps downloaded from https://download.kortforsyningen.dk/
shp2dta using dkmap/KOMMUNE, genid(id) replace ///
	database(data/MapMunicipality_data) ///
	coordinates(data/MapMunicipality_coor) ///
	gencentroids(labelloc)
use data/MapMunicipality_data, clear
destring KOMKODE, gen(area)
replace REGIONKODE=substr(REGIONKODE, 3,2)
destring REGIONKODE, replace

save data/MapMunicipality_data, replace

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat include_kom
contract _all, freq(N) zero
rename include_kom area

merge 1:1 area agecat using data/popDK_age_municipality.dta, assert(match using) nogen
recode N (.=0)


** SIR by year
qui: dstdize N pop agecat, by(area) using(data/popEU_age.dta) format(%12.3g)
matrix sir_area=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_area=sir_area'


*** Load
bysort area: egen Ntotal=total(N)
bysort area: egen poptotal=total(pop)
keep area Ntotal poptotal
duplicates drop
sort area
svmat double sir_area, name(matcol)

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

*** Graph SIR on map
merge 1:m area using data/MapMunicipality_data, assert(match) nogen
spmap sir_areaAdjusted ///
		using data/MapMunicipality_coor, id(id) /// 
		fcolor(Blues) ///
		clmethod(custom) clbreaks(-0.1 0.1 2 4 6 8 10) ///
		legend(order(1 "0" 2 "0.1-2" 3 "2-4" 4 "4-6" 5 "6-8" 6 "8-10") pos(2)) ///
		// label(select(keep if showlab==1 & (sir_areaAdjusted==0 | sir_areaAdjusted>6)) xcoord(x_labelloc) ycoord(y_labelloc) label(KOMNAVN) size(1))
graph export results/FigSirByMun${exportformat} ${exportoptions}