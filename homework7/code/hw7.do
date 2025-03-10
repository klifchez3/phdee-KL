* =============================== *
* Phd-EE Spring 2025 			  *
* Homework 7 					  *
* Kelly Lifchez					  * 
* =============================== *


clear 
set more off 

*Paths
	if "`c(username)'"== "klifchez3" {                              
		global dt "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework7" 
		global in "$dt\data" 
		global out "$dt\output"  
	}
	if "`c(username)'"== "kellylifchez" {
		global dt "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework7"
		global in "$dt/data" 
		global out "$dt/output" 
	}
	
ssc install rdrobust
ssc install blindschemes
ssc install rddensity
ssc install lpdensity

set scheme plotplainblind

	
import delimited "$in/instrumentalvehicles.csv", clear


*** Question 1: Estimate impact of mpg on price using rdrobust command 

//length is running variable, discontinuity is instrument for mpg
//c(225) is the cutoff, p(1) indicates a linear model and bwselect(mserd) selects the CCT optimal bandwidth
rdrobust mpg length, c(225) p(1) bwselect(mserd)


preserve
rdplot mpg length, c(225) p(1) covs(car) genvars ///
graph_options(ytitle(Miles per Gallon) xtitle(Vehicle Length (in inches)) ///
legend(position(6)) ///
title("RDD: Fuel Efficiency and Car Length")) ///
saving("$out/rdplot_stata_q1.pdf", replace) ///
export graph "$out/rdplot_stata_q1.pdf", replace
restore 

// second stage regression - regress price on predicted mpg and car type 
regress price rdplot_hat_y car, robust

//check against fuzzy RD-IV: 
rdrobust price length, c(225) fuzzy(mpg) covs(car) p(1) bwselect(mserd)

//check direct price - length relationship
preserve
rdplot price length, c(225) p(1) covs(car) genvars ///
graph_options(ytitle(Price) xtitle(Length) ///
legend(position(6)) ///
title("RDD: Fuel Efficiency and Price")) ///
saving("$out/rdplot_stata_price.pdf", replace) ///
restore 


*** Question 2: Instrument validity? 
//another check on instrument validity 
rddensity length, c(225)

rddensity length, c(225) plot
graph export "$out/rddensity_plot.pdf", replace
