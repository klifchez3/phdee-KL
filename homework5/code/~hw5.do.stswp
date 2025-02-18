*===================================*
* PHD-EE Homework 5 				*
* Kelly Lifchez 					*
* February 17, 2025					*
*===================================*

clear
set more off 

*Paths
	if "`c(username)'"== "klifchez3" {                              
		global dt "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework5"
		global inputpath "$dt\data" 
		global outputpath "$dt\output"  
	}
	if "`c(username)'"== "kellylifchez" {
		global dt "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework5"
		global inputpath "$dt/data" 
		global outputpath "$dt/output" 
	}

ssc install twowayfeweights, replace //pretty sure this is same package as fetwowayweights, according to https://github.com/chaisemartinPackages/twowayfeweights?tab=readme-ov-file 
ssc install reghdfe, replace
ssc install csdid


use "$inputpath/energy_staggered.dta", clear

**						**
**# Part 1: Hourly Data **
**						**

** 1. Generate Stata time variable and treatment cohort variable 

//Convert datetime string to Stata datetime variable with double precision
gen double time = clock(datetime, "MDYhms")
format time %tc

order time id treatment

// Generate treatment cohort by first treated 
bysort id treatment: egen first=min(time) if treatment==1
bysort id (first): replace first=first[1] if missing(first)
format first %tc

// Generate treatment cohort variable using csdid 
egen cohort=csgvar(treatment), ivar(id) tvar(time)
format cohort %tc

// Generate time variable that counts up one each hour
sort time
egen hour=seq(), by(id)


** 2. Use the twowayfeweights command to find the fixed effect weights for the treatment variable

// Estimate TWFE weights using the twowayfeweights command
twowayfeweights energy cohort hour treatment, type(feTR)


** 3. Estimate the treatment effect using household fixed effects and hourly indicators
reghdfe energy treatment temperature precipitation relativehumidity, absorb(id hour) cluster(id)

eststo: reghdfe energy treatment temperature precipitation relativehumidity, absorb(id hour) cluster(id)

// Export results to LaTeX
esttab using "$outputpath/tab_Q1_3.tex", se ar2 replace label ///
    title("TWFE Regression Results") ///
    b(3) se(3) star(* 0.05 ** 0.01) ///
    keep(treatment) ///
    addnotes("Standard errors in parentheses")
	
save "$inputpath/energy_staggered_hourly.dta", replace
	
	
**						**
**# Part 2: Daily Data  **
**						**

use "$inputpath/energy_staggered_hourly.dta", clear

**** Something wrong! Need to check original data. Should not have cases where devicegroup = 0 and treatment = 1. Returning to this later. 	

** Set Up 

gen date = dofc(time)
format date %td

// Collapse the data to daily averages and sums
collapse (mean) temperature relativehumidity precipitation (sum) energy (first) treatment cohort  zip size occupants devicegroup, by(id date)

// Generate the new treatment variable
bysort id (date): gen treatment_daily = sum(treatment)
replace treatment_daily = treatment_daily > 0

// Generate the new treatment cohort variable
egen daily_cohort = group(id) if treatment_daily == 1

// Generate day
sort date 
egen day = seq(), by(id)

// Generate cohort 
bysort id treatment : egen first = min(day) if treatment == 1
bysort id (first): replace first = first[1] if missing(first)

// Save daily data
save "$inputpath/energy_staggered_day.dta", replace

** 1. Estimate the treatment effect using household fixed effects and daily indicators

// TWFE DiD

est clear 

eststo: reghdfe energy treatment temperature precipitation relativehumidity, absorb(date id) vce(cluster id)

// Export results to LaTeX
esttab using "$outputpath/daily_twfe.tex", se ar2 replace label ///
    title("TWFE Regression Results") ///
    b(3) se(3) star(* 0.05 ** 0.01) ///
    keep(treatment) ///
    addnotes("Standard errors in parentheses")

** 2. Estimate an event study using the reghdfe command

use "$inputpath/energy_staggered_day.dta", clear

// Create event_time variable
gen event_time = day - first

char event[omit] -1
xi i.event, pref(_T)

preserve
reghdfe energy  _T* temperature precipitation relativehumidity, absorb(id) vce(cluster id)
estimates store reg1
coefplot reg1, drop(_cons precipitation relativehumidity temperature) xlabel(3 "-27" 6 "-24" 9 "-21" 12 "-18" 15 "-15" 18 "-12" 21 "-9" 24 "-6" 27 "-3" 30 "0" 33 "3" 36 "6" 39 "9" 42 "12" 45 "15" 48 "18" 51 "21" 54 "24" 57 "27", labsize(mediumsmall))  vertical xline(29) recast(rarea) ciopts(recast(rarea) lcolor(gs13) fcolor(gs13)) xtitle("Days relative to device adoption", size(mediumlarge)) ytitle("Daily Energy Consumption (kWh)", size(mediumlarge)) graphregion(fcolor(white)) plotregion(style(none)) msymbol(circle) mcolor(green) saving("es_coef",replace) 
graph export "$outputpath/es_coef.pdf", replace
restore


** 3. Estimate the treatment effect using the eventdd command

// Event Study Using eventdd
eventdd energy temperature precipitation relativehumidity, hdfe absorb(id) timevar(event_time) cluster(id) graph_op(ytitle("Daily Energy Consumption (kWh)", size(mediumlarge)) xlabel(-27(3)27) xtitle("Days relative to device adoption", size(mediumlarge))) ci(rarea)
	
graph export "outputpath/es_eventdd.pdf", replace 


** 4. Estimate the treatment effect using the csdid command

// Callaway Sant'Anna DiD
csdid energy temperature precipitation relativehumidity, ivar(id) time (day) gvar(first) wboot reps(50)
estat simple
estat event
csdid_plot, ytitle("Daily Energy Consumption (kWh)", size(medium)) xlabel(-30(10)30) xtitle("Days relative to device adoption", size(medium)) xline(-.5, lpattern(dash) lcolor(gs7) lwidth(0.3))
graph export "$outputpath/es_csdid.pdf", replace


