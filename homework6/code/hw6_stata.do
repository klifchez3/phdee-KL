* ============================= *
* Phd EE Homework 6 			*
* Kelly Lifchez 				*
* February 24 2025				* 
* ============================= * 

clear
set more off 

*Paths
	if "`c(username)'"== "klifchez3" {                              
		global dt "C:\Users\klifchez3\GaTech Dropbox\Kelly Lifchez\phdee-KL\homework6"
		global inputpath "$dt\data" 
		global outputpath "$dt\output"  
	}
	if "`c(username)'"== "kellylifchez" {
		global dt "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework6"
		global inputpath "$dt/data" 
		global outputpath "$dt/output" 
	}

ssc install blindschemes, all
ssc install coefplot, replace
set scheme plotplainblind, permanently
ssc install weakivtest
ssc install avar
	
import delimited "$inputpath/instrumentalvehicles.csv", clear

*** Q1: 1. Use ivregress liml to compute the limited information maximum likelihood estimate 

//weight as iv, heteroskedasticity robust standard errors
ivregress liml price car (mpg = weight), vce(robust)
estimates store liml

//report in table using outreg2
outreg2 [liml] using "$outputpath/stata_Q1.tex", label 2aster tex(frag) dec(2) replace ctitle("Limited Information Maximum Likelihood Estimates using Weight as IV")

*** Q2: Use weakivtest to estimate the Montiel-Olea-Pflueger effective  F-statistic 

ivregress liml price car (mpg = weight), vce(robust)
weakivtest
