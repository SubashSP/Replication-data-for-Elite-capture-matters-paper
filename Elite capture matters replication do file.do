/******************************************************************************
Paper : Elite capture matters: insights from interventions in seed systems with 
		women self-help groups in India
Date  : 21 january 2026 (last revised)
******************************************************************************/
clear
macro drop _all
set more off
* Install heckprobitfixed rho
*ssc install outreg2  // For table export
*net install heckprobitfixedrho  // If public
/******************************************************************************
Set director and path for files in the folder
*******************************************************************************/
cd "E:\Agricultural system elite paper 2026\Data and analysis"
*Change the director based on the location of the data files
*Data source
use "Elite capture baseline data.dta", clear
*Setting global varibales
global xlist1 age age_sq TotalFamilyMembers land_ha i.social_category i.education i.house_type i.economic_status mnrega i.membership_new i.homogenous_group
global xlist2 age age_sq TotalFamilyMembers land_ha i.social_category i.education i.house_type i.economic_status mnrega i.membership_new 
*Table 3. Estimates from Heckprobit model on elite capture and its effect
***using heckprobit command to check for rho value
heckprobit seed_producer_2016 $xlist2, select(cbsp= $xlist1)
outreg2 using  Table3_final2.doc, append cttop(Model 1) dec(3)  
*Figure  Plotting estimated coefficients for values of rho on succes

tempfile coefstore
tempname handle
postfile `handle' rho b_membership se_membership using `coefstore', replace
local rhos -0.99	-0.95	-0.9	-0.85	-0.8	-0.75	-0.7	-0.65	-0.6	-0.55	-0.5	-0.45	-0.4	-0.35	-0.3	-0.25	-0.2	-0.15	-0.1	-0.05	0


foreach r of local rhos {
    heckprobit_fixedrho seed_producer_2016 $xlist1, ///
        select(cbsp = $xlist1) rho(`r')
    
    scalar coef = _b[2.membership_new]
    scalar se = _se[2.membership_new]
    
    post `handle' (`r') (coef) (se)
}
postclose `handle'
use `coefstore', clear

gen ub = b_membership + 1.96* se_membership 
gen lb = b_membership - 1.96* se_membership

twoway ///
    (rarea ub lb rho, color(gs12)) ///
    (line b_membership rho, lcolor(black) lwidth(thick)) ///
    (function y=0, range(rho) lcolor(black) lpattern(dash) lwidth(medium)), ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    ylabel(, format(%9.2f)) ///
    xlabel(, format(%9.2f)) ///
    ytitle("Coefficient on Elite") ///
    xtitle("Rho value") ///
    title("Success in seed production") ///
    legend(off)
	

tempfile coefstore
tempname handle
postfile `handle' rho outcome_coef outcome_se select_coef select_se using `coefstore', replace
local rhos -0.99	-0.95	-0.9	-0.85	-0.8	-0.75	-0.7	-0.65	-0.6	-0.55	-0.5	-0.45	-0.4	-0.35	-0.3	-0.25	-0.2	-0.15	-0.1	-0.05	0


foreach r of local rhos {
    heckprobit_fixedrho seed_producer_2016 $xlist2, ///
        select(cbsp = $xlist1) rho(`r')
    
    * Outcome equation: 2.membership_new (main equation)
    scalar outcome_coef = _b[2.membership_new]
    scalar outcome_se = _se[2.membership_new]
    
    * Selection equation: cbsp:2.membership_new (selection eq prefix)
    scalar select_coef = _b[cbsp:2.membership_new]
    scalar select_se = _se[cbsp:2.membership_new]
    
    post `handle' (`r') (outcome_coef) (outcome_se) (select_coef) (select_se)
}
postclose `handle'
use `coefstore', clear

gen ub_outcome = outcome_coef + 1.96* outcome_se 
gen lb_outcome = outcome_coef - 1.96* outcome_se


* Graph 1: Outcome Equation
twoway ///
    (rarea ub_outcome lb_outcome rho, color(gs12)) ///
    (line outcome_coef rho, lcolor(black) lwidth(thick)) ///
    (function y=0, range(rho) lcolor(black) lpattern(dash) lwidth(medium)), ///
    graphregion(color(white)) plotregion(color(white)) ///
    ylabel(, format(%9.2f)) xlabel(, format(%9.2f)) ///
    ytitle("Elite coefficients") xtitle("Rho value") ///
    title("Successful seed production", size(medsmall)) ///
    legend(off) ///
    name(outcome_graph, replace)

* Graph 2: Selection Equation  
twoway ///
    (rarea ub_select lb_select rho, color(gs10)) ///
    (line select_coef rho, lcolor(black) lwidth(medthick)) ///
    (function y=0, range(rho) lcolor(black) lpattern(dash) lwidth(medium)), ///
    graphregion(color(white)) plotregion(color(white)) ///
    ylabel(, format(%9.2f)) xlabel(, format(%9.2f)) ///
    ytitle("Elite coefficients") xtitle("Rho value") ///
    title("Selection as seed producer", size(medsmall)) ///
    legend(off) ///
    name(selection_graph, replace)

* Combine side-by-side
graph combine outcome_graph selection_graph, ///
    cols(2) graphregion(color(white)) plotregion(color(white)) ///
    


