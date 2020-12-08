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

* Settings for headings
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
putdocx text  ("Annual incidence rates of PPGL patients diagnosed in Denmark. Incidence rates are age-standardized to the European Standard Population 2013.")


** IR by age
local figno = `figno'+1
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Figure `figno' - Crude Incidence Rates of PPGL by Age")
putdocx paragraph, halign(center)
putdocx image results/FigIrByAge${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Annual crude incidence rates of new PPGL patients diagnosed in Denmark by age at diagnosis. Incidence rates are reported in 10-year averages.")


** Prevalence
local figno = `figno'+1
putdocx pagebreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Figure `figno' - Standardized Prevalence Patients with Previous or Current PPGL in Denmark, 1977-${lastyear}")
putdocx paragraph, halign(center)
putdocx image results/FigPrevByYear${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Prevalence of PPGL patients living in Denmark December 31st each year. Patients are considered prevalent from date of diagnosis until death or emigration. Prevalences are age-standardized to the European Standard Population 2013. Most PPGL patients diagnosed before 1977 were likely missed, which explain the low prevalence in the beginning of the study period.")


** SIR by MoD, symptoms, and Tumor size
local figno = `figno'+1
putdocx pagebreak
putdocx paragraph, style(Heading2) `fontHeading2' spacing(after, 0.1)
putdocx text ("Figure `figno' - Standardized Incidence Rates of PPGL by A) Mode of Discovery, B) Symptoms at Presentation, and C) Tumor Size")

putdocx paragraph, halign(center) spacing(after, 0.1) spacing(before, 0.1)
putdocx text ("A"), linebreak
putdocx image results/FigSirByMod${exportformat}, height(2.5 in) linebreak
putdocx text ("B"), linebreak
putdocx image results/FigSirBySymp${exportformat}, height(2.5 in) linebreak
putdocx text ("C"), linebreak
putdocx image results/FigSirBySize${exportformat}, height(2.5 in)

putdocx paragraph, spacing(after, 0)
putdocx text ("Notes: "), bold
putdocx text  ("Incidence rates in the North and Central Danish regions by A) mode of discovery, B) symptoms, and C) tumor size. Incidence rates are reported in 10-year means and age-standardized to the European Standard Population 2013. Mode of discovery and symptoms at presentation are defined in methods with details in Supplementary 2. Tumor size refers to the largest tumor diameter.")


*** Tables
local tabno = 0


** PatChar by Period
local tabno = `tabno'+1
putdocx sectionbreak, landscape
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Table `tabno' - Patient and Tumor Characteristics by Year of Diagnosis")

use results/TabCharByPeriod.dta, clear

* Add footnote symbols
replace rowname =  rowname + " *" if onlyavailable==1 // Clinical var only available in North/Central regions

ds cell_*
putdocx table tbl1 = data("rowname `r(varlist)'"), width(100%) layout(autofitcontents)
putdocx table tbl1(., .), ${tablecells} 
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
levelsof row if !mi(firstcol) & mi(seccol)
putdocx table tbl1(`r(levels)', .), ${tablerows}
putdocx paragraph
putdocx text ("Abbreviations and symbols: "), bold
putdocx text  ("CA, catecholamines; E, epinephrine; NE, nor-epinephrine, PHEO, pheochromocytoma; PARA, paraganglioma; PPGL, pheochromocytoma and catecholamine-secreting paraganglioma; * Clinical data was only available for the North and Central Danish Regions (n=$Ncrnr)."), linebreak
putdocx text ("Notes: "), bold
putdocx text  (`"Tumor size refers to the largest tumor diameter. Hereditary PPGL includes both patients with genetically confirmed pathogenic mutations and clinically diagnosed hereditary syndromes. "'), linebreak
putdocx text  (`"Percentages were calculated out of patients with non-missing data. Reasons for missing clinical data: ${footnote_TabCharByPeriod_miss}."')



** Prev By Sex and Age
local tabno = `tabno'+1
putdocx sectionbreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Table `tabno' - Prevalence of Patients with Previous or Current PPGL per 1,000,000 persons at $lastyear by Sex and Age")

use results/TabPrevBySexAge.dta, clear

* Add footnote symbols
replace rowname =  rowname + " *" if inlist(grp, 0, -1, .)==0 // Age-specific (crude)
replace rowname =  rowname + " #" if grp==0 // Age-adjusted

ds cell_*
putdocx table tbl1 = data("rowname `r(varlist)'"), width(100%) layout(autofitwindow)
putdocx table tbl1(., .), ${tablecells} 
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
local x = _N
putdocx table tbl1(`x', .), ${tabletotalrow}

putdocx paragraph
putdocx text ("Abbreviations and symbols: "), bold
putdocx text  ("PPGL, pheochromocytoma and catecholamine-secreting paraganglioma; * Age-specific (i.e. crude) prevalence; # Age-standardized to the European Standard Population 2013."), linebreak
putdocx text ("Notes: "), bold
putdocx text  (`"Prevalence of PPGL per 1,000,000 persons in Denmark at Dec 31 $lastyear (n=$Nprev) by sex and age. Patients were considered prevalent from diagnosis until death or emigration. Patient age refers to their age at Dec 31 $lastyear and not age at diagnosis."')



*** Supplementary
local supno = 0

putdocx sectionbreak, landscape
putdocx paragraph, style(Heading1) `fontHeading1'
putdocx text ("Supplementary")


** RECORD checklist (header only, table is manually copy/pasted)
local supno = `supno'+1
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - RECORD Checklist")
putdocx paragraph


** Tab MoD details
local supno = `supno'+1
putdocx sectionbreak, landscape
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Details on Mode of Discovery")

use results/TabModDetails.dta, clear
ds cell_*
putdocx table tbl1 = data("firstcol `r(varlist)'"), layout(autofitcontents)
putdocx table tbl1(., .), ${tablecells}
putdocx table tbl1(., 1/3), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
levelsof row if !mi(firstcol) & row!=1
putdocx table tbl1(`r(levels)', .), ${tablerows}

putdocx paragraph
putdocx text ("Abbreviations: "), bold
putdocx text  ("CT, computed tomography; FNA, fine-needle aspiration; MEN, multiple endocrine neoplasia; MRI, magnetic resonance imaging; NF1, neurofibromatosis type 1; SDH, succinate dehydrogenase; US, ultrasound; vHL, von Hippel-Lindau."), linebreak
putdocx text ("Notes: "), bold
putdocx text  ("Details on mode of discovery were available for $Nmod out of $Ncrnr patients diagnosed in North and Central Danish ($Nmodmiss had missing records). Adrenal incidentaloma as defined by recent guidelines (Fassnacht M, Arlt W, Bancos I, Dralle H, Newell-Price J, Sahdev A, et al. Management of adrenal incidentalomas: European Society of Endocrinology Clinical Practice Guideline in collaboration with the European Network for the Study of Adrenal Tumors. Eur J Endocrinol. 2016 Aug 1;175(2):G1–34.).")


** Fig Histogram AgeOverall, AgeBySex and AgeByMod
local supno = `supno'+1
putdocx sectionbreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Age at Diagnosis A) by Sex and B) by Mode of Discovery")

putdocx paragraph, halign(center) spacing(after, 0.1) spacing(before, 0.1)
putdocx text ("A"), linebreak
putdocx image results/FigAgeBySex${exportformat}, height(2.3 in) linebreak
putdocx text ("B"), linebreak
putdocx image results/FigAgeByMod${exportformat}, height(2.3 in) 

putdocx paragraph, spacing(after, 0)
putdocx text ("Notes: "), bold
putdocx text  ("Histogram of age at diagnosis for PPGL patients. Figure A includes all patients diagnosed with PPGL in Denmark (n=$Ninci) and figure B only includes patients from North and Central Danish Regions (n=$Ncrnr). Mode of discovery is defined in methods with details in Supplementary 2.")


** Fig IR by sex
local supno = `supno'+1
putdocx sectionbreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Crude Incidence Rates by Sex")
putdocx paragraph, halign(center)
putdocx image results/FigIrBySex${exportformat}, height(5 in)
putdocx paragraph
putdocx text ("Notes: "), bold
putdocx text  ("Crude incidence rates of new PPGL patients diagnosed in Denmark by sex. Incidence rates are reported in 10-year averages.")


** Fig SIR by region
local supno = `supno'+1
putdocx sectionbreak
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Standardized Incidence Rates by Region")
putdocx paragraph
putdocx image results/FigSirByRegion${exportformat}, height(5 in)
putdocx paragraph

putdocx text ("Notes: "), bold
putdocx text  ("Incidence rates of PPGL in North and Central Region, where PPGL diagnosis was confirmed in medical records, compared to the remaining three Danish regions, where the PPGL diagnosis was validated algorithm. Incidence rates are reported in 10-year averages and age-standardized to the European Standard Population 2013.")


** PatChar by Mod
local supno = `supno'+1
putdocx sectionbreak, landscape
putdocx paragraph, style(Heading2) `fontHeading2'
putdocx text ("Supplementary `supno' - Patient and Tumor Characteristics by Mode of Discovery")

use results/TabCharByMod.dta, clear

ds cell_*
foreach var in `r(varlist)' {
	replace `var' = subinstr(`var', " (", "_p(", 1) if length(`var')>=13 & !mi(rowname) // add paragraph to wide cells (cells with median and range)
}

putdocx table tbl1 = data("rowname `r(varlist)'"), width(100%) layout(autofitcontents)
putdocx table tbl1(., .), ${tablecells} 
putdocx table tbl1(., 1), ${tablefirstcol}
putdocx table tbl1(1, .), ${tablefirstrow}
levelsof row if !mi(firstcol) & mi(seccol)
putdocx table tbl1(`r(levels)', .), ${tablerows}
putdocx paragraph
putdocx text ("Abbreviations: "), bold
putdocx text  ("CA, catecholamines; E, epinephrine; NE, nor-epinephrine, PHEO, pheochromocytoma; PARA, paraganglioma; PPGL, pheochromocytoma and catecholamine-secreting paraganglioma. "), linebreak
putdocx text ("Notes: "), bold
putdocx text  (`"Tumor size refers to the largest tumor diameter. Hereditary PPGL includes both patients with genetically confirmed pathogenic mutations and clinically diagnosed hereditary syndromes."'), linebreak
putdocx text  (`"Percentages were calculated out of patients with non-missing data. Reasons for missing clinical data: ${footnote_TabCharByMod_miss}. Reasons for not undergoing surgery included$footnote_reasonnosurg."')



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