* =============================== *
* Phd-EE Spring 2025 			  *
* Homework 7 					  *
* Kelly Lifchez					  * 
* =============================== *


clear 
set more off 

*Paths
	if "`c(username)'"== "klifchez3" {                              
		global dt "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework8" 
		global in "$dt\data" 
		global out "$dt\output"  
	}
	if "`c(username)'"== "kellylifchez" {
		global dt "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework8"
		global in "$dt/data" 
		global out "$dt/output" 
	}
	
ssc install rdrobust
ssc install blindschemes
ssc install rddensity
ssc install lpdensity

set scheme plotplainblind

	
use "$in/recycling_hw.dta", clear

*** Question 1: Produce a yearly plot of the recycling rate for NYC and the controls ***

* Generate the line plot for recycling rates by year for all three cities

preserve 
collapse (mean) recyclingrate, by(year nyc nj ma) 

twoway (line recyclingrate year if nyc == 1, lcolor(orange) lwidth(medium)) ///
       (line recyclingrate year if nj == 1, lcolor(blue) lwidth(medium)) ///
       (line recyclingrate year if ma == 1, lcolor(navy) lwidth(medium)), ///
       legend(order(1 "NYC" 2 "NJ" 3 "MA")) ///
	   xlabel(#7, nogrid labsize(medium)) ylabel(#7, nogrid labsize(medsmall)) ///
       xtitle("Year", size(medlarge) margin(medium)) ytitle("Fraction of waste recycled", size(medlarge) margin(medium)) ///
	   xline(2001.5 2004.5, lpattern(dot) lcolor(black%70) lwidth(medthin))
	   graph export "$out/recycling_rates.pdf", as(pdf) replace

restore	   

sum year


*** Question 2: Estimate the effect of the pause on the recycling rate in NYC using TWFE reg and data from 1997 - 2004. Cluster SE at the region level. ***

// Drop years after 2004
drop if year > 2004

//treatment is NYC between 2002 - 2004
gen treatment = 0
replace treatment = 1 if nyc == 1 & year >=2002

//TWFE
reghdfe recyclingrate treatment, absorb(region year) cluster(region)


*** Question 3: Do the SDID version of the TWFE regression ***


sdid recyclingrate region year treatment, vce(bootstrap) reps(200) graph  ///
graph export "$out/sdid_graph.pdf", replace

*** Question 4: Estimate the event study regression with the full sample ***

use "$in/recycling_hw.dta", clear

tab year, gen(y)
forval year=1(1)12 {
	gen dy_`year'= (nyc * y`year')
}	

reghdfe recyclingrate dy_1-dy_4 dy_6-dy_12 incomepercapita nonwhite , absorb(region year) cluster(region)

coefplot, keep(dy*) yline(0) omitted baselevels coeflabels(1.dy_1 = "1997") vertical
graph export "$out/event_study.pdf", replace


*** Question 5: Generate the synthetic control estimates using synth and synth_runner ***

ssc install synth, all
cap ado uninstall synth_runner 
net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace

** a) plot raw outcomes for treated and control groups over time
use "$in/recycling_hw.dta", clear

egen recycling_mean = mean(recyclingrate), by(year nyc)
twoway (line recycling_mean year if nyc==1, sort) ///
       (line recycling_mean year if nyc==0, sort), ///
        xtitle("Year") ytitle("Recycling Rate") ///
        legend(label(1 "NYC (Treatment)") label(2 "MA + NJ (Control)") pos(6) rows(1))
		graph export "$out/q5_a.pdf", replace

** b) plot raw outcomes for treated and synthetic control groups over time
use "$in/recycling_hw.dta", clear

gen state = "NYC"
replace state = "NJ" if nj ==1
replace state = "MA" if ma ==1
encode state, gen(nstate)
encode region, gen(nregon)

egen average_nyc = mean(recyclingrate) if nyc ==1, by(year nyc)
replace average_nyc = recyclingrate if average_nyc ==.

drop if region == "Bronx"|region == "Queens"

sort state region year
egen stateregionuniqueid = concat(state region)

replace stateregionuniqueid = "NYC" if stateregionuniqueid == "NYCBrooklyn"

encode stateregionuniqueid, gen(nstateuniqueregion)


tsset nstateuniqueregion year
synth average_nyc incomepercapita(1997(1)2001) nonwhite(1997(1)2001) munipop2000 collegedegree2000 democratvoteshare2000, trunit(208) trperiod(2002) fig
graph export "$out/q5_b.pdf", replace

** c) plot the estimated synthetic control effects and placebo effects over time  

synth_runner average_nyc incomepercapita(1997(1)2001) nonwhite(1997(1)2001) munipop2000 collegedegree2000 democratvoteshare2000, trunit(208) trperiod(2002) gen_vars

ereturn list

graph twoway (line effect year if nstateuniqueregion != 208, lc(gray) lwidth(vthin)) (line effect year if nstateuniqueregion == 208, lc(green)), xtitle("Year") ytitle("Effects") xlabel(1997(2)2008) legend(label(1 "Donors") label(2 "NYC") pos(6) rows(1)) 
			
* placebo effects by using e(pvals)  
pval_graphs

*(d)The plot of final synthetic control estimates over time.
cap ado uninstall synth_runner
net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace
mat list e(b)
effects_graphs
single_treatment_graphs
