***** 4_SirOverall.do *****

*** Calculations
** Cases per year
use data/cohort_ppgl.dta, clear
keep if ppgl_incident==1
keep agecat year_index
contract _all, freq(N) zero
rename year_index year

merge 1:1 year agecat using data/popDK_age.dta, assert(match using) nogen


** Crude IR
ci means N, poisson exposure(pop)
local format = `", 0.01), "%03.2f")"' // 3 significant numbers
local ir_mean = string(round(`r(mean)'*1000000 `format'
local ir_lb = string(round(`r(lb)'*1000000 `format'
local ir_ub = string(round(`r(ub)'*1000000 `format'


** Overall SIR
gen dummy=1
dstdize N pop agecat, by(dummy) using(data/popEU_age.dta) format(%12.3g)
local format = `", 0.01), "%03.2f")"' // 3 significant numbers
local sir_mean = string(round(r(adj)[1,1]*1000000 `format'
local sir_lb = string(round(r(lb_adj)[1,1]*1000000 `format'
local sir_ub = string(round(r(ub_adj)[1,1]*1000000 `format'


** SIR by year
qui: dstdize N pop agecat, by(year) using(data/popEU_age.dta) format(%12.3g)
matrix sir_y=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_y=sir_y'


** SIR by period
recode year $period10ycat, gen(period) label(period_)
bysort agecat period: egen poptotal=total(pop)
bysort agecat period: egen Ntotal=total(N)
keep agecat poptotal period Ntotal
rename poptotal pop
duplicates drop
dstdize Ntotal pop agecat, by(period) using(data/popEU_age.dta) format(%12.3g)
matrix sir_p=  r(Nobs) \ r(crude) \ r(adj) \ r(lb) \ r(ub)
matrix sir_p=sir_p'



*** Export results
** Load
drop _all

svmat double sir_y, name(matcol)
egen Year= seq(), f(1977) t($lastyear) b(1)
label var Year "Year"

svmat double sir_p, name(matcol)
gen Period = _n if _n<=4
label values Period period_
label var Period "Period"

* Change to SIR per million
ds *Crude *Adjusted *Left *Right
foreach var in `r(varlist)' {
	qui: replace `var' = `var' * 1000000 // IR Per million
}


** Graph (SIR per year)
twoway ///
	(scatter sir_yAdjuste Year, mcolor(${color1})) /// mean
	(rcap sir_yLeft sir_yRight Year, lcolor(${color1})) /// 95% CI
	, legend(off) /// legend
	xlabel(1977 "1977" 1982 "1982" 1987 "1987" 1992 "1992" 1997 "1997" 2002 "2002" 2007 "2007" 2012 "2012" $lastyear "$lastyear") ///
	xmtick(1977(1)$lastyear) ///
	ylabel(0(1)10) ///
	ytitle("Age-standardized IR" "per 1,000,000 years") //
graph export results/FigSirByYear${exportformat} ${exportoptions}

putdocx begin
putdocx paragraph, halign(center)
putdocx image results/FigSirByYear${exportformat}, height(5 in)
putdocx save results/FigSirByYear, replace


** Text
* SIR first to last year
local format = `", 1), "%01.0f")"' // 1 significant number
local sirfirst_mean = string(round(sir_yAdjusted[1] `format'
local sirfirst_lb = string(round(sir_yLeft[1] `format'
local sirfirst_ub = string(round(sir_yRight[1] `format'

local format = `", 0.1), "%02.1f")"' // 2 significant numbers
local sirlast_mean = string(round(sir_yAdjusted[_N] `format'
local sirlast_lb = string(round(sir_yLeft[_N] `format'
local sirlast_ub = string(round(sir_yRight[_N] `format'

local format = `", 0.1), "%02.1f")"' // 2 significant numbers
local foldincrease = string(round(sir_yAdjusted[_N]/sir_yAdjusted[1] `format'

* SIR by period
local format = `", 0.1), "%02.1f")"' // 2 significant numbers
local sirper1_mean = string(round(sir_pAdjusted[1] `format'
local sirper1_lb = string(round(sir_pLeft[1] `format'
local sirper1_ub = string(round(sir_pRight[1] `format'

local format = `", 0.01), "%03.2f")"' // 3 significant number
local sirper2_mean = string(round(sir_pAdjusted[2] `format'
local sirper2_lb = string(round(sir_pLeft[2] `format'
local sirper2_ub = string(round(sir_pRight[2] `format'

local sirper3_mean = string(round(sir_pAdjusted[3] `format'
local sirper3_lb = string(round(sir_pLeft[3] `format'
local sirper3_ub = string(round(sir_pRight[3] `format'

local sirper4_mean = string(round(sir_pAdjusted[4] `format'
local sirper4_lb = string(round(sir_pLeft[4] `format'
local sirper4_ub = string(round(sir_pRight[4] `format'

local perlabel1 : label period_ 1
local perlabel2 : label period_ 2
local perlabel3 : label period_ 3
local perlabel4 : label period_ 4

putdocx begin
putdocx paragraph, style(Heading2)
putdocx text ("SIR overall")
putdocx paragraph
putdocx text ("Overall crude IR: `ir_mean' (95%CI `ir_lb'-`ir_ub')"), linebreak
putdocx text ("Overall SIR: `sir_mean' (95%CI `sir_lb'-`sir_ub')"), linebreak

putdocx text ("SIR increased from `sirfirst_mean' (95%CI `sirfirst_lb'-`sirfirst_ub') in 1977 to `sirlast_mean' (95%CI `sirlast_lb'-`sirlast_ub') in ${lastyear}."), linebreak
putdocx text ("Fold increase from 1977-${lastyear}: `foldincrease'"), linebreak

putdocx text ("SIR `perlabel1': `sirper1_mean' (95%CI `sirper1_lb'-`sirper1_ub')"), linebreak
putdocx text ("SIR `perlabel2': `sirper2_mean' (95%CI `sirper2_lb'-`sirper2_ub')"), linebreak
putdocx text ("SIR `perlabel3': `sirper3_mean' (95%CI `sirper3_lb'-`sirper3_ub')"), linebreak
putdocx text ("SIR `perlabel4': `sirper4_mean' (95%CI `sirper4_lb'-`sirper4_ub')"), linebreak

putdocx save results/TextSirOverall, replace


** Table (SIR per year)
ds Year, not
foreach var in `r(varlist)' {
	qui: tostring `var', force replace format(%03.2f)
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
putdocx save results/TabSirByYear, replace
