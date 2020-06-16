***** Pheo-inci_SirOverall.do *****
*** Calculate SIR
** Cases per year
use cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat year_index
gen N=1
collapse (sum) N, by(agecat year_index)
rename year_index year

merge 1:1 year agecat using popDK_age.dta, assert(match using) nogen
recode N (.=0)

** Overall crude IR
ci means N, poisson exposure(pop)
local format = `", 0.01), "%03.2f")"' // 3 significant numbers
local ir_mean = string(round(`r(mean)'*1000000 `format'
local ir_lb = string(round(`r(lb)'*1000000 `format'
local ir_ub = string(round(`r(ub)'*1000000 `format'


** Overall SIR
gen dummy=1
dstdize N pop agecat, by(dummy) using(popEU_age.dta) format(%12.3g)
local format = `", 0.01), "%03.2f")"' // 3 significant numbers
local sir_mean = string(round(r(adj)[1,1]*1000000 `format'
local sir_lb = string(round(r(lb_adj)[1,1]*1000000 `format'
local sir_ub = string(round(r(ub_adj)[1,1]*1000000 `format'


** Sir by year
qui: dstdize N pop agecat, by(year) using(popEU_age.dta) format(%12.3g) 

* Load results
matrix sir_y=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_y=sir_y'
clear
svmat double sir_y, name(matcol) 
egen Year= seq(), f(1977) t($lastyear) b(1)
label var Year "Year"

* Change SIR to SIR per million
foreach var in sir_yCrude sir_yAdjusted sir_yLeft sir_yRight {
	qui: replace `var' = `var' * 1000000 // IR Per million
}

* SIR first to last year
local format = `", 1), "%01.0f")"' // 1 significant number
local sirfirst_mean = string(round(sir_yAdjusted[1] `format'
local sirfirst_lb = string(round(sir_yLeft[1] `format'
local sirfirst_ub = string(round(sir_yRight[1] `format'

local format = `", 0.1), "%02.1f")"' // 2 significant numbers
local sirlast_mean = string(round(sir_yAdjusted[_N] `format'
local sirlast_lb = string(round(sir_yLeft[_N] `format'
local sirlast_ub = string(round(sir_yRight[_N] `format'


** Graph
twoway ///
	(scatter sir_yAdjuste Year, mcolor(${colour1})) /// mean
	(rcap sir_yLeft sir_yRight Year, lcolor(${colour1})) /// 95% CI
	, legend(off) /// legend 
	xlabel(1977 "1977" 1982 "1982" 1987 "1987" 1992 "1992" 1997 "1997" 2002 "2002" 2007 "2007" 2012 "2012" $lastyear "$lastyear") ///
	xmtick(1977(1)$lastyear) ///
	ylabel(0(1)10) ///
	ytitle("Age-standardized IR" "per 1,000,000 years") //
graph export fig_SirByYear${exportformat} ${exportoptions}



** Export to report
* Text
putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("SIR overall")
putdocx paragraph
putdocx text ("Overall crude IR was `ir_mean' (95%CI `ir_lb'-`ir_ub') per 1,000,000 person-years. "), linebreak
putdocx text ("Overall age-standardized IR (:SIR) was `sir_mean' (95%CI `sir_lb'-`sir_ub') per 1,000,000 person-years. SIR per 1,000,000 person-years increased from `sirfirst_mean' (95%CI `sirfirst_lb'-`sirfirst_ub') in 1977 to `sirlast_mean' (95%CI `sirlast_lb'-`sirlast_ub') in ${lastyear}. ")
putdocx save Results_TextSirOverall, replace

* Graph
putdocx begin
putdocx paragraph, halign(center)
putdocx image fig_SirByYear${exportformat}, height(5 in)
putdocx save Results_FigSirByYear, replace

* SIR in supplementary
ds Year, not
foreach var in `r(varlist)' {
	tostring `var', force replace format(%03.2f)
}
rename sir_yCrude Crude
gen SIR = sir_yAdjusted + " (" + sir_yLeft + "-" + sir_yRight + ")"

putdocx begin
putdocx paragraph
putdocx table tbl1 = data("Year Crude SIR"), varnames 
putdocx table tbl1(., .), ${tableoverall}
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
local lastrow = _N
putdocx table tbl1(3(2)`lastrow', .), ${tablerows}
putdocx save Results_SupSirByYear, replace