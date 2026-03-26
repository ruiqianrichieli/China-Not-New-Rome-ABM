> **Note:** This is an anonymized repository for peer review purposes. Author identifying information has been removed. The de-anonymized version with full attribution will be made public upon acceptance.

# China is Not the New Rome: An Agent-Based Model Test of the Supply-Side Theory

## Overview

This repository contains the simulation code, output data, and online supplementary materials for the paper *"China is Not the New Rome: An Agent-Based Model Test of the Supply-Side Theory."*

The study formalizes the core mechanisms of the rational choice theory of religion (Stark and Finke 2000) and the strict church thesis (Iannaccone 1994) as an agent-based model (ABM), then tests whether these mechanisms can produce the sustained 7–10% annual Christian growth predicted for China by Yang (2016a) and Stark and Wang (2015). The model simulates a population of 5,000 agents over 100 years (1980–2080), with five Christian denominations, four non-Christian competitor religions, heterogeneous religious receptivity, network-based evangelism, and optional government regulation.

## Repository Structure

```
├── model_functions.R           # Core ABM mechanics (agent creation, conversion,
│                               #   retention, R dynamics, demography, network)
├── run_batch.R                 # Batch runner: 5 scenarios × 4 R distributions
├── batch_run_whole_codes.R     # Master script: runs all scenarios, sensitivity
│                               #   tests, and generates tables/figures
├── utils.R                     # Scenario parameter presets and helper functions
├── verification.R              # 7 boundary-condition verification checks
├── Sensitivity_test.R          # Secular cohort sensitivity analysis
├── README.md                   # This file
│
└── online_supplement/
    ├── ODD_protocol.md         # Full ODD protocol (Grimm et al. 2020)
    ├── supplement_index.md     # Guide to all supplementary materials
    ├── tables/                 # All output CSV tables (24 files)
    │   ├── tbl_overview.csv
    │   ├── tbl_trajectory.csv
    │   ├── tbl_timeseries.csv
    │   ├── tbl_r_composition.csv
    │   ├── tbl_denominations.csv
    │   ├── tbl_nc_groups.csv
    │   ├── tbl_mega_test.csv
    │   ├── tbl_secular_sensitivity.csv
    │   └── tbl_*_sensitivity.csv   # 18 sensitivity analysis tables
    └── figures/                # All output figures (23 PNG files)
        ├── scenario_comparison.png
        ├── secular_sensitivity.png
        ├── tier1_panel.png
        ├── mega_test.png
        ├── convert_share.png
        ├── robustness_panel.png
        └── *_sensitivity.png       # 18 individual sensitivity plots
```

## Requirements

- **R** ≥ 4.4.0
- **R packages:** `dplyr`, `tidyr`, `ggplot2`, `parallel`

No additional installation is required. All packages are available on CRAN.

## How to Reproduce

### Full reproduction (all 20 baseline scenarios + sensitivity tests)

```r
source("batch_run_whole_codes.R")
```

This runs the complete pipeline:
1. 20 baseline scenarios (5 scenarios × 4 R distributions × 30 replications)
2. Secular cohort sensitivity analysis (5 levels × 30 replications)
3. 18 parameter sensitivity tests
4. Mega-test (all parameters maximized)
5. Generates all CSV tables and PNG figures

**Estimated runtime:** 4–8 hours on a modern multi-core machine (parallelized).

### Verification only

```r
source("verification.R")
```

Runs 7 boundary-condition checks in under 5 minutes. Expected output: 7 PASS, 0 FAIL.

### Secular sensitivity only

```r
source("Sensitivity_test.R")
```

### Single scenario

```r
source("run_batch.R")
result <- run_scenario(scenario = 4, R_dist = "right_skewed", n_reps = 30)
```

## Model Design

The model implements four supply-side mechanisms from the rational choice theory of religion:

| Mechanism | Implementation |
|-----------|---------------|
| Competitive evangelism | Christian groups recruit from unaffiliated pool; exposure proportional to group size × evangelism intensity |
| Strict-church retention | Higher-strictness denominations have lower exit rates, stronger R boosts, better intergenerational transmission |
| Cross-religion recruitment | NC members may convert to Christianity (unilateral; reverse not modeled) |
| Persecution solidarity | Under state regulation, high-R Christians receive solidarity boost; low-R receive deterrence penalty |

Christianity is given every structural advantage: sole active recruiter, unilateral cross-conversion, highest evangelism intensity, and network structures that concentrate evangelistic exposure.

## Scenario Design

| Scenario | Regulation | Persecution |
|----------|-----------|-------------|
| 1: Christians + Nones (Free) | None | Never |
| 2: Christians + Passive NC (Free) | None | Never |
| 3: Christians + Active NC (Free) | None | Never |
| 4: Christians + Passive NC (Regulated) | 50% suppression | 5% trigger |
| 5: Christians + Active NC (Regulated) | 50% suppression | 5% trigger |

Each scenario is crossed with four R distributions: Normal, Bimodal, Right-skewed, and Left-skewed.

## Key Findings

1. The R distribution (demand), not supply-side mechanisms, determines the growth trajectory.
2. Persecution filters the church but does not grow it: the deterrence channel has zero detectable effect; the solidarity channel saturates immediately.
3. Strict churches win internal competition but cannot expand the convert pool.
4. Even without intergenerational decline, Christianity peaks at ~11.6% under regulation.
5. The 18-parameter sensitivity analysis and mega-test confirm the demand ceiling is robust.

## Online Supplement

The `online_supplement/` folder contains:

- **Supplement A:** Full ODD protocol (`ODD_protocol.md`)
- **Supplement B:** All 24 output tables (`tables/`)
- **Supplement C:** All 23 output figures (`figures/`)
- **Supplement D:** Verification test results (`verification.R` output)

See `online_supplement/supplement_index.md` for a detailed guide.

## Citation

[Author]. 2026. "China is Not the New Rome: An Agent-Based Model Test of the Supply-Side Theory." [Journal]. Code and data available at [this repository].

## License

Code is released under the MIT License. Data tables and figures are provided for academic use.

## AI Disclosure

[Removed for anonymous review.]
