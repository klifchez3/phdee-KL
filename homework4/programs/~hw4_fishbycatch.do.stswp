*===================================*
* Homework 4 Fish Bycatch Analysis  *
* Kelly Lifchez | February 10, 2025 *
*===================================*

clear all 
set more off 

cd "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4"
//cd "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework4"


//global inputpath "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework4\data"
global inputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4/data"
global outputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework4/output"
//local outputpath "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework4\output"

import delimited "$inputpath/fishbycatch.csv", clear

* Reshape data from wide to long format
reshape long shrimp salmon bycatch, i(firm) j(month)

** a) OLS Regression with firm indicators as direct fixed effects 

* Create indicator variables for each firm 
tabulate firm, gen(firm_)

* Create treatment indicator for treated firms in treatment period
gen treatment = 0
replace treatment = 1 if treated == 1 & month > 12

* run TWFE regression 

xtset firm month

reg bycatch i.firm i.month treatment firmsize shrimp salmon, vce(cluster firm)

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
reg demeaned_bycatch demeaned_shrimp demeaned_salmon demeaned_treatment demeaned_firmsize, vce(cluster firm)

** c) Table results 
est clear
//label vars 
label var shrimp "Shrimp"
label var salmon "Salmon"
label var bycatch "Bycatch"
label var treatment "Treatment"

label var demeaned_bycatch "Bycatch (demeaned)"
label var demeaned_shrimp "Shrimp (demeaned)"
label var demeaned_salmon "Salmon (demeaned)"
label var demeaned_treatment "Treatment (demeaned)"


** Column A - OLS Fixed Effects
reg bycatch i.firm i.month treatment shrimp salmon firmsize, vce(cluster firm)
est store col1
    
* Column B - Within-Transformation
reg demeaned_bycatch demeaned_treatment demeaned_shrimp demeaned_salmon demeaned_treatment demeaned_firmsize i.month, vce(cluster firm)
est store col2
    
* Create a table to display the estimates for Column A and Column B
estout col1 col2 using ///
    "$outputpath/did_regression_stata.tex", cells(b(fmt(%9.3f) star) se(par fmt(%9.3f))) ///
    starlevels(* .1 ** .05 *** .01) style(tex) ///
    keep(treatment shrimp salmon demeaned_treatment demeaned_shrimp demeaned_salmon) ///
    mlabels(, dep) collabels(,none) ///

// Display the output path
display "Saving table to: $outputpath/did_regression_stata.tex"




