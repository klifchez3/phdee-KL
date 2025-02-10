*===================================*
* Homework 4 Fish Bycatch Analysis  *
* Kelly Lifchez | February 10, 2025 *
*===================================*

clear all 
set more off 

global inputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4/data"
global outputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4/output"

import delimited "$inputpath/fishbycatch.csv", clear

* Reshape data from wide to long format
reshape long shrimp salmon bycatch, i(firm) j(month)

** a) 

* Create indicator variables for each firm 
tabulate firm, gen(firm_)

* Create treatment indicator for treated firms in treatment period
gen treatment = 0
replace treatment = 1 if treated == 1 & month > 12

* run TWFE regression 

xtset firm month

reg bycatch i.firm i.month treatment firmsize shrimp salmon

** b) Perform within-transformation

* Calculate firm-specific means
bysort firm: egen mean_bycatch = mean(bycatch)
bysort firm: egen mean_shrimp = mean(shrimp)
bysort firm: egen mean_salmon = mean(salmon)
bysort firm: egen mean_firmsize = mean(firmsize)
bysort firm: egen mean_treatment = mean(treatment)

* Demean the variables
gen demeaned_bycatch = bycatch - mean_bycatch
gen demeaned_shrimp = shrimp - mean_shrimp
gen demeaned_salmon = salmon - mean_salmon
gen demeaned_firmsize = firmsize - mean_firmsize
gen demeaned_treatment = treatment - mean_treatment

* Run the regression on demeaned variables including time period indicators
reg demeaned_bycatch demeaned_shrimp demeaned_salmon demeaned_treatment demeaned_firmsize i.month

