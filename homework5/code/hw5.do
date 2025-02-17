*===================================*
* PHD-EE Homework 5 				*
* Kelly Lifchez 					*
* February 17, 2025					*
*===================================*

clear
set more off 

//cd "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework5"
cd "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework5"

//global inputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework5/data"
//global outputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework5/output"

global inputpath "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework5\data"
global outputpath "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework5\output"


//ssc install twowayfeweights, replace //pretty sure this is same package as fetwowayweights, according to https://github.com/chaisemartinPackages/twowayfeweights?tab=readme-ov-file 
//ssc install reghdfe, replace

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
reghdfe energy treatment temperature precipitation relativehumidity, absorb(id time_counter) cluster(id)

eststo: reghdfe energy treatment temperature precipitation relativehumidity, absorb(id time_counter) cluster(id)

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

gen day = dofc(time)
format day %td

// Collapse the data to daily averages and sums
collapse (mean) temperature relativehumidity precipitation (sum) energy (first) treatment cohort  zip size occupants devicegroup, by(id day)

// Generate the new treatment variable
bysort id (day): gen treatment_daily = sum(treatment)
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
save "$outputpath/energy_staggered_day.dta", replace

** 1. Estimate the treatment effect using household fixed effects and daily indicators

// TWFE DiD
eststo: reghdfe energy treatment temperature precipitation relativehumidity, absorb(date id) vce(cluster id)

// Export results
esttab using "$outputpath/daily_twfe.tex", label replace ///
	b(4) se(4) ////
	mtitles("Energy consumption (kWh)") collabel(none) star(* 0.10 ** 0.05 *** 0.01) nonum ///
	coeflabels(treatment "ATT" relativehumidity "Relative Humidity (\%)" temperature "Temperature (F)" precipitation "Precipitation (in)" ) ///
		ar2 sfmt(%8.2f)

** 2. Estimate an event study using the reghdfe command

// Event Study
use "$inputpath/energy_staggered_day.dta", clear

// Create event_time variable
gen event_time = day - first_treated

// Make dummies for period and omit -1 period
char event_time[omit] -1
xi i.event_time, pref(_T)

// Define positions
local pos_of_neg_2 = 28 
local pos_of_zero = `pos_of_neg_2' + 2
local pos_of_max = `pos_of_zero' + 29

// Event study
reghdfe energy _T* temperature precipitation relativehumidity, absorb(id) vce(cluster id)

// Extract coefficients and standard errors
forvalues i = 1/`pos_of_max' {
    if `i' <= `pos_of_neg_2' | `i' >= `pos_of_zero' {
        scalar b_`i' = _b[_Tevent_tim_`i']
        scalar se_v2_`i' = _se[_Tevent_tim_`i']
    }
}

// Drop existing variables if they exist
capture drop order b high low

// Generate new variables
gen order = .
gen b = .
gen high = .
gen low = .

// Fill in the variables
local i = 1
forvalues day = 1/`pos_of_max' {
    if `day' <= `pos_of_neg_2' | `day' >= `pos_of_zero' {
        local event_time = `day' - 2 - `pos_of_neg_2'
        replace order = `event_time' in `i'
        replace b = b_`day' in `i'
        replace high = b_`day' + 1.96 * se_v2_`day' in `i'
        replace low = b_`day' - 1.96 * se_v2_`day' in `i'
        local i = `i' + 1
    }
}

// Add the omitted period
replace order = -1 in `i'
replace b = 0 in `i'
replace high = 0 in `i'
replace low = 0 in `i'

return list

// Plot the results
twoway rarea low high order if order <= 29 & order >= -29, fcol(gs14) lcol(white) msize(1) ///
    || connected b order if order <= 29 & order >= -29, lw(0.6) col(white) msize(1) msymbol(s) lp(solid) ///
    || connected b order if order <= 29 & order >= -29, lw(0.2) col("71 71 179") msize(1) msymbol(s) lp(solid) ///
    || scatteri 0 -29 0 29, recast(line) lcol(gs8) lp(longdash) lwidth(0.5) ///
    xlab(-30(10)30, nogrid labsize(2) angle(0)) ///
    ylab(, nogrid labs(3)) ///
    legend(off) ///
    xtitle("Day since receiving treatment", size(5)) ///
    ytitle("Daily energy consumption (kWh)", size(5)) ///
    xline(-.5, lpattern(dash) lcolor(gs7) lwidth(0.6))

graph export "$outputpath/es_reghdfe.pdf", replace
	
** 3. Estimate the treatment effect using the eventdd command

// Event Study Using eventdd
eventdd energy temperature precipitation relativehumidity, hdfe absorb(id) timevar(event_time) cluster(id) graph_op(ytitle("Daily energy consumption (kWh)", size(5)) xlabel(-30(10)30) xtitle("Day since receiving treatment", size(5)))
	
graph export "outputpath/es_eventdd.pdf", replace 
	

twoway rarea low high order if order<=29 & order >= -29 , fcol(gs14) lcol(white) msize(1) /// estimates
		|| connected b order if order<=29 & order >= -29, lw(0.6) col(white) msize(1) msymbol(s) lp(solid) /// highlighting
		|| connected b order if order<=29 & order >= -29, lw(0.2) col("71 71 179") msize(1) msymbol(s) lp(solid) /// connect estimates
		|| scatteri 0 -29 0 29, recast(line) lcol(gs8) lp(longdash) lwidth(0.5) /// zero line 
			xlab(-30(10)30 ///
					, nogrid labsize(2) angle(0)) ///
			ylab(, nogrid labs(3)) ///
			legend(off) ///
			xtitle("Days since receiving treatment", size(5)) ///
			ytitle("Daily energy consumption", size(5)) ///
			xline(-.5, lpattern(dash) lcolor(gs7) lwidth(0.6)) 			
graph export "$outputpath/eventdd.pdf", replace 

** 4. Estimate the treatment effect using the csdid command

// Callaway Sant'Anna DiD
csdid energy temperature precipitation relativehumidity, ivar(id) time (day) gvar(first_treated) wboot reps(50)
estat simple
estat event
csdid_plot, ytitle("Daily energy consumption", size(5)) xlabel(-30(10)30) xtitle("Days since treatment", size(5)) xline(-.5, lpattern(dash) lcolor(gs7) lwidth(0.3))
graph export "$outputpath/event_study_csdid.pdf", replace

//trash
//Create treatment cohort variable
// egen treatment_cohort = group(id) if devicegroup == 1
// tab treatment_cohort
//
// replace treatment_cohort = 0 if treatment_cohort ==.
//
