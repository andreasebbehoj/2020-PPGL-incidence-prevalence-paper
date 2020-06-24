***** 4_SirByMunicipality.do *****

*** Prepare map
	// Maps downloaded from https://download.kortforsyningen.dk/
shp2dta using dkmap/KOMMUNE, genid(id) replace ///
	database(MapMunicipality_data) ///
	coordinates(MapMunicipality_coor) ///
	gencentroids(labelloc)
use MapMunicipality_data, clear
destring KOMKODE, gen(area)
replace REGIONKODE=substr(REGIONKODE, 3,2)
destring REGIONKODE, replace

save MapMunicipality_data, replace

*** Calculations
** Cases per year
use cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat include_kom
contract _all, freq(N) zero
rename include_kom area

merge 1:1 area agecat using popDK_age_municipality.dta, assert(match using) nogen
recode N (.=0)


** SIR by year
qui: dstdize N pop agecat, by(area) using(popEU_age.dta) format(%12.3g)
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
merge 1:m area using MapMunicipality_data, assert(match) nogen
spmap sir_areaAdjusted ///
		using MapMunicipality_coor, id(id) /// 
		fcolor(Blues) ///
		clmethod(custom) clbreaks(-0.1 0.1 2 4 6 8 10) ///
		legend(order(1 "0" 2 "0.1-2" 3 "2-4" 4 "4-6" 5 "6-8" 6 "8-10") pos(2)) ///
		// label(select(keep if showlab==1 & (sir_areaAdjusted==0 | sir_areaAdjusted>6)) xcoord(x_labelloc) ycoord(y_labelloc) label(KOMNAVN) size(1))
graph export Results_FigSirByMun${exportformat} ${exportoptions}

putdocx begin
putdocx paragraph, halign(center)
putdocx image Results_FigSirByMun${exportformat}, height(5 in)
putdocx save Results_FigSirByMun, replace

