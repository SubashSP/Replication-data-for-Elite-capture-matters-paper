# Codebook — Elite Capture Baseline Data

**File:** `data/raw/elite_capture_baseline_replication.dta`  
**Unit of observation:** Individual woman SHG member  
**Source:** Baseline survey, India

---

## Outcome & Selection Variables

| Variable | Type | Description |
|----------|------|-------------|
| `seed_producer_2016` | binary (0/1) | Outcome: Successfully became a seed producer by 2016 |
| `cbsp` | binary (0/1) | Selection: Was selected as a community-based seed producer (CBSP) |

---

## Covariates

| Variable | Type | Description |
|----------|------|-------------|
| `age` | continuous | Age of respondent (years) |
| `age_sq` | continuous | Age squared (for non-linear age effect) |
| `TotalFamilyMembers` | continuous | Total household members |
| `land_ha` | continuous | Land owned (hectares) |
| `social_category` | categorical | Social group: 1=SC, 2=ST, 3=OBC, 4=General |
| `education` | categorical | Education level (ordered) |
| `house_type` | categorical | Housing quality indicator |
| `economic_status` | categorical | Asset-based economic status (proxy for wealth) |
| `mnrega` | binary (0/1) | Participation in MNREGA scheme |
| `membership_new` | categorical | SHG membership type; **key elite capture variable** — category 2 indicates elite/non-poor membership |
| `homogenous_group` | binary (0/1) | Group is socioeconomically homogeneous; used as **exclusion restriction** in selection equation only |

---

## Notes on Identification Strategy

The exclusion restriction is `homogenous_group`: included in the selection equation (cbsp) but excluded from the outcome equation (seed_producer_2016). The rationale is that group homogeneity affects who gets *selected* as a seed producer but has no direct effect on production *success* conditional on selection.

`heckprobitfixedrho` is used for sensitivity analysis across fixed values of ρ ∈ [−0.99, 0] to assess how sensitive the elite capture coefficient is to assumptions about selection-on-unobservables.
