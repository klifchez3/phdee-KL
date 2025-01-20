** phd-ee homework 2 - stata script for kwh analysis
** kelly lifchez
** 01/20/2025

clear all
set more off 

global inputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework2/data/raw" 
global outputpath "/Users/kellylifchez/GaTech Dropbox/Kelly Lifchez/phdee-KL/homework2/output" 
	
import delimited "$inputpath/kwh.csv", clear	

eststo nonretro: quietly estpost summarize electricity if retrofit == 0
eststo retro: quietly estpost summarize electricity if retrofit == 1
eststo diff: quietly estpost ttest electricity, by(retrofit) unequal
esttab nonretro retro diff, cells("mean(pattern(1 1 0) fmt(3)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(3)) t(pattern(0 0 1) par fmt(3))") label
