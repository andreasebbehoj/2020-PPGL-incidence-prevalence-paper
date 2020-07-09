***** 4_Report.do *****
clear
putdocx clear
file close _all

*** Setup document
putdocx begin, ///
	pagenum(decimal) ///
	footer(pfooter) ///
	pagesize(A4) ///
	font("Times new roman", 11, black)
putdocx paragraph, tofooter(pfooter)
putdocx text ("Page ")
putdocx pagenumber, bold
putdocx text (" of ")
putdocx pagenumber, totalpages bold


*** Settings for headings
local fontHeading1 = `"font("Times new roman", 15, black)"'
local fontHeading2 = `"font("Times new roman", 13, black)"'

*** Figures
local figno = 0

putdocx paragraph, style(Heading1) `fontHeading1'
putdocx text ("Figures and Tables")

** SIR overall
local figno = `figno'+1
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Figure `figno' - Standardized Incidence Rates of PPGL in Denmark, 1977-${lastyear}")
putdocx paragraph, halign(center)
putdocx image results/FigSirByYear${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Incidence rates of new PPGL patients diagnosed in Denmark each year. Incidence rates are age-standardized to the European Standard Population 2013.")

** IR by age and sex
local figno = `figno'+1
putdocx pagebreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Figure `figno' - Incidence Rates of PPGL by Age and Sex")
putdocx paragraph, halign(center)
putdocx text ("A")
putdocx image results/FigIrByAge${exportformat}, height(5 in)
putdocx paragraph, halign(center)
putdocx text ("B")
putdocx image results/FigIrBySex${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Crude incidence rates of new PPGL patients diagnosed in Denmark by A) age at diagnosis and B) sex.")



** SIR by MoD, symptoms, and Tumor size
local figno = `figno'+1
putdocx pagebreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Figure `figno' - Standardized Incidence Rates of PPGL by A) Mode of Discovery, B) Symptoms at Presentation, and C) Tumor Size")
putdocx paragraph, halign(center)
putdocx text ("A")
putdocx image results/FigSirByMod${exportformat}, height(5 in)
putdocx paragraph, halign(center)
putdocx text ("B")
putdocx image results/FigSirBySymp${exportformat}, height(5 in)
putdocx paragraph, halign(center)
putdocx text ("C")
putdocx image results/FigSirBySize${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Incidence rates in the North and Central Danish regions by A) mode of discovery, B) symptoms, and C) tumor size. Incidence rates are reported in 10-year averages and age-standardized to the European Standard Population 2013.")


** Prevalence
local figno = `figno'+1
putdocx pagebreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Figure `figno' - Standardized Prevalence of PPGL in Denmark, 1977-${lastyear}")
putdocx paragraph, halign(center)
putdocx image results/FigPrevByYear${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Prevalence of PPGL patients living in Denmark December 31st each year. Patients are considered prevalent from date of diagnosis until death or emigration. Prevalences are age-standardized to the European Standard Population 2013. Most PPGL patients diagnosed before 1977 were likely missed, which explain the low prevalence in the beginning of the study period")



*** Tables
local tabno = 0

** Patient Characteristics
local tabno = `tabno'+1
putdocx sectionbreak, landscape
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Table `tabno' - Patient and Tumor Characteristics by Year of Diagnosis")

use results/TabPatChar.dta, clear
putdocx table tbl1 = data("rowname cell_0 cell_1 cell_2 cell_3 cell_4"), width(100%) layout(autofitcontents)
putdocx table tbl1(., .), ${tablecells} 
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
levelsof row if !mi(firstcol) & mi(seccol)
putdocx table tbl1(`r(levels)', .), ${tablerows}
putdocx paragraph
putdocx text ("Abbreviations: "), bold
putdocx text  ("E, epinephrine; NE, nor-epinephrine, PPGL, pheochromocytoma and catecholamine-secreting paraganglioma. ")
putdocx text ("Notes: "), bold
putdocx text  (`"Patients for whom the relevant health records, radiology report, or laboratory report could not be found are recorded as "Not found". Tumor size refers to the largest tumor diameter. Hereditary PPGL includes both patients with genetically confirmed pathogenic mutations and clinically diagnosed hereditary syndromes."')


*** Supplementary graphs/tables
local supno = 0

putdocx sectionbreak
putdocx paragraph, style(Heading1) `fontHeading1'
putdocx text ("Supplementary")

** SIR by year table
local supno = `supno'+1
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Age-standardized Incidence Rates per Year")

use results/TabSirByYear.dta, clear
putdocx table tbl1 = data("Year Crude SIR"), varnames
putdocx table tbl1(., .), ${tablecells}
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
local lastrow = _N
putdocx table tbl1(3(2)`lastrow', .), ${tablerows}

putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("xxx")

** SIR by municipality map
local supno = `supno'+1
putdocx pagebreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Age-standardized Incidence Rates in each Municipality")
putdocx paragraph
putdocx image results/FigSirByMun${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Incidence rates by patients' municipality of residence at time of diagnosis. Incidence rates are standardized to European Standard Population 2013 and reported in averages for 1977-$lastyear.")


*** Save Figures and Tables report
putdocx save results/FigTablesCombined, replace


*** Combine and save text report
local files : dir "results" files "Text*.docx"
local textappend = ""
foreach file of local files {
	local textappend = "`textappend' results/`file'"
}
di "`textappend'"
putdocx append `textappend', saving(results/ReportCombined, replace)