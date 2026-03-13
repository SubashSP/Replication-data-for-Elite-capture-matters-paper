******************************************************************************
 * Project : Elite Capture Matters: Insights from Interventions in Seed 
 *           Systems with Women SHGs in India
 * Authors : [Authors]
 * Date    : 21 January 2026 (last revised)
 *
 * File    : code/analysis_main.do
 * Purpose : Main replication script. Runs all analysis in sequence:
 *             1. Setup & globals
 *             2. Table 3: Heckprobit estimates
 *             3. Figure: Rho sensitivity for outcome equation
 *             4. Figure: Combined rho sensitivity (outcome + selection)
 *
 * Inputs  : data/raw/elite_capture_baseline_replication.dta
 * Outputs : output/tables/Table3_final.doc
 *           output/figures/rho_sensitivity_outcome.gph  (.png)
 *           output/figures/rho_sensitivity_combined.gph (.png)
 *
 * Notes   : Requires Stata packages: heckprobitfixedrho, outreg2
 *           Install with:
 *             ssc install outreg2
 *             net install heckprobitfixedrho
 ******************************************************************************/

clear all
macro drop _all
set more off
version 16.0


/*----------------------------------------------------------------------------
  0. INSTALL DEPENDENCIES (uncomment on first run)
  ---------------------------------------------------------------------------
  ssc install outreg2
  net install heckprobitfixedrho
  ---------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------
  1. PATHS
  Run this do file from the repo root:  do code/analysis_main.do
  All paths are relative to the repo root.
  ---------------------------------------------------------------------------*/

local project_root "`c(pwd)'"

local data_raw     "`project_root'/data/raw"
local data_derived "`project_root'/data/derived"
local out_tables   "`project_root'/output/tables"
local out_figures  "`project_root'/output/figures"

display "Project root : `project_root'"
display "Raw data     : `data_raw'"
display "Tables out   : `out_tables'"
display "Figures out  : `out_figures'"


/*----------------------------------------------------------------------------
  2. GLOBAL VARIABLE LISTS
  xlist1 : full covariate set (used in selection equation)
  xlist2 : restricted covariate set (excludes group homogeneity,
            used in outcome equation — satisfies exclusion restriction)
  ---------------------------------------------------------------------------*/

global xlist1 age age_sq TotalFamilyMembers land_ha ///
    i.social_category i.education i.house_type ///
    i.economic_status mnrega i.membership_new i.homogenous_group

global xlist2 age age_sq TotalFamilyMembers land_ha ///
    i.social_category i.education i.house_type ///
    i.economic_status mnrega i.membership_new


/*----------------------------------------------------------------------------
  3. LOAD DATA
  ---------------------------------------------------------------------------*/

use "`data_raw'/elite_capture_baseline_replication.dta", clear
display "Obs loaded: `=_N'"


/*----------------------------------------------------------------------------
  4. TABLE 3: HECKPROBIT MODEL ESTIMATES
  Outcome  : seed_producer_2016
  Selection: cbsp
  ---------------------------------------------------------------------------*/

heckprobit seed_producer_2016 $xlist2, select(cbsp = $xlist1)

outreg2 using "`out_tables'/Table3_final.doc", ///
    replace cttop("Model 1") dec(3) ///
    title("Table 3. Heckprobit estimates: elite capture and seed production")


/*----------------------------------------------------------------------------
  5. FIGURE: RHO SENSITIVITY — OUTCOME EQUATION ONLY
  ---------------------------------------------------------------------------*/

tempfile coefstore_outcome
tempname handle_outcome

postfile `handle_outcome' rho b_membership se_membership ///
    using `coefstore_outcome', replace

local rhos -0.99 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 ///
           -0.5  -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0

foreach r of local rhos {
    quietly heckprobit_fixedrho seed_producer_2016 $xlist1, ///
        select(cbsp = $xlist1) rho(`r')
    scalar coef = _b[2.membership_new]
    scalar se   = _se[2.membership_new]
    post `handle_outcome' (`r') (coef) (se)
}
postclose `handle_outcome'

use `coefstore_outcome', clear

gen ub = b_membership + 1.96 * se_membership
gen lb = b_membership - 1.96 * se_membership

twoway ///
    (rarea ub lb rho, color(gs12)) ///
    (line b_membership rho, lcolor(black) lwidth(thick)) ///
    (function y = 0, range(rho) lcolor(black) lpattern(dash) lwidth(medium)), ///
    graphregion(color(white)) plotregion(color(white)) ///
    ylabel(, format(%9.2f)) xlabel(, format(%9.2f)) ///
    ytitle("Coefficient on Elite") xtitle("Rho value") ///
    title("Success in seed production") legend(off)

graph save   "`out_figures'/rho_sensitivity_outcome.gph", replace
graph export "`out_figures'/rho_sensitivity_outcome.png", replace


/*----------------------------------------------------------------------------
  6. FIGURE: RHO SENSITIVITY — COMBINED (OUTCOME + SELECTION)
  ---------------------------------------------------------------------------*/

use "`data_raw'/elite_capture_baseline_replication.dta", clear

tempfile coefstore_combined
tempname handle_combined

postfile `handle_combined' rho outcome_coef outcome_se select_coef select_se ///
    using `coefstore_combined', replace

local rhos -0.99 -0.95 -0.9 -0.85 -0.8 -0.75 -0.7 -0.65 -0.6 -0.55 ///
           -0.5  -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0

foreach r of local rhos {
    quietly heckprobit_fixedrho seed_producer_2016 $xlist2, ///
        select(cbsp = $xlist1) rho(`r')

    scalar outcome_coef = _b[2.membership_new]
    scalar outcome_se   = _se[2.membership_new]
    scalar select_coef  = _b[cbsp:2.membership_new]
    scalar select_se    = _se[cbsp:2.membership_new]

    post `handle_combined' (`r') (outcome_coef) (outcome_se) ///
                                  (select_coef)  (select_se)
}
postclose `handle_combined'

use `coefstore_combined', clear

gen ub_outcome = outcome_coef + 1.96 * outcome_se
gen lb_outcome = outcome_coef - 1.96 * outcome_se
gen ub_select  = select_coef  + 1.96 * select_se
gen lb_select  = select_coef  - 1.96 * select_se

twoway ///
    (rarea ub_outcome lb_outcome rho, color(gs12)) ///
    (line outcome_coef rho, lcolor(black) lwidth(thick)) ///
    (function y = 0, range(rho) lcolor(black) lpattern(dash) lwidth(medium)), ///
    graphregion(color(white)) plotregion(color(white)) ///
    ylabel(, format(%9.2f)) xlabel(, format(%9.2f)) ///
    ytitle("Elite coefficients") xtitle("Rho value") ///
    title("Successful seed production", size(medsmall)) ///
    legend(off) name(outcome_graph, replace)

twoway ///
    (rarea ub_select lb_select rho, color(gs10)) ///
    (line select_coef rho, lcolor(black) lwidth(medthick)) ///
    (function y = 0, range(rho) lcolor(black) lpattern(dash) lwidth(medium)), ///
    graphregion(color(white)) plotregion(color(white)) ///
    ylabel(, format(%9.2f)) xlabel(, format(%9.2f)) ///
    ytitle("Elite coefficients") xtitle("Rho value") ///
    title("Selection as seed producer", size(medsmall)) ///
    legend(off) name(selection_graph, replace)

graph combine outcome_graph selection_graph, ///
    cols(2) graphregion(color(white)) plotregion(color(white))

graph save   "`out_figures'/rho_sensitivity_combined.gph", replace
graph export "`out_figures'/rho_sensitivity_combined.png", replace

display "===== Analysis complete ====="
display "Tables  : `out_tables'/"
display "Figures : `out_figures'/"
