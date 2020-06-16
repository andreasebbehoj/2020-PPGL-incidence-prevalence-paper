***** Pheo-inci_PopEU.do *****
/*
European Standard Population 2013 edition - Appendix F
Link: https://ec.europa.eu/eurostat/web/products-manuals-and-guidelines/-/KS-RA-13-028
*/

clear
input age_from	age_to	pop
0	0	1000
1	4	4000
5	9	5500
10	14	5500
15	19	5500
20	24	6000
25	29	6000
30	34	6500
35	39	7000
40	44	7000
45	49	7000
50	54	7000
55	59	6500
60	64	6000
65	69	5500
70	74	5000
75	79	4000
80	84	2500
85	89	1500
90	94	800
95	100	200
end

recode age_to $agecat, gen(agecat) label(agecat_)
label var agecat "Age category"
bysort agecat: egen poptotal=total(pop)
drop age_from age_to pop 
rename poptotal pop
duplicates drop

save popEU_age.dta, replace