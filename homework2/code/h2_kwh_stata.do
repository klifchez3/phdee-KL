** phd-ee homework 2 - stata script for kwh analysis
** kelly lifchez
** 01/20/2025

clear all
set more off 

global inputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework2/data/raw" 
global outputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework2/output" 
	
import delimited "$inputpath/kwh.csv", clear	

*** Question 1 - Balance Table

//label variables
label variable electricity "Electricity"
label variable sqft "Square Feet"
label variable temp "Temperature"

local vars "electricity sqft temp"

//store summary values for each group then export as table 
eststo nonretro: quietly estpost summarize `vars' if retrofit == 0
eststo retro: quietly estpost summarize `vars' if retrofit == 1
eststo diff: quietly estpost ttest `vars', by(retrofit) unequal
esttab nonretro retro diff using "$outputpath/stata_balancetable7.tex", cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0) fmt(3) par) b(pattern(0 0 1) fmt(3)) p(pattern(0 0 1) fmt(3) par)") label 



*** Question 2 - Scatter plot of electricity and square footage

twoway (scatter electricity sqft if retrofit == 0, mcolor(orange)) ///
		(scatter electricity sqft if retrofit ==1, mcolor(green)), ///
		legend(label(1 "Non-Retrofit") label(2 "Retrofit")) ///
		title("Electricity Usage by Household Square Footage") ///
		xtitle("Square Feet") ///
		ytitle("Electricity (kWh)") ///
		saving("$outputpath/stata_scatter.pdf", replace)



*** Question 3 - Regression Analysis

* regression

label variable retrofit "Retrofit Treatment"

reg electricity retrofit sqft temp, vce(robust)
	
* table using outreg2
outreg2 using "$outputpath/stata_resultstable.tex", label tex(fragment) replace






//create kernel density plot of electricity usage by retrofit status to check against python

twoway (kdensity electricity if retrofit == 0, lcolor(orange) lpattern(solid)) ///
       (kdensity electricity if retrofit == 1, lcolor(green) lpattern(dash)), ///
       legend(label(1 "Non-Retrofit") label(2 "Retrofit")) ///
       title("Electricity Usage by Retrofit Status") ///
       xtitle("Electricity Usage (kWh)") ///
       ytitle("Density") ///
       saving("$outputpath/stata_kdensity.pdf", replace)
