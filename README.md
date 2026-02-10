# China is Not the New Rome

### An Agent-Based Model Test of the Supply-Side Theory

**Abstract.** This paper formalizes the supply-side (rational choice) theory of religion as an agent-based model and tests whether its core mechanisms — competitive evangelism, strict-church filtering, and persecution-as-catalyst — can produce the 7–10% annual Christian growth rates predicted for China. Across 20 scenario configurations (5 competitive environments × 4 demand distributions, 30 replications each), I find that supply-side mechanisms alone never generate explosive growth under empirically plausible conditions. Growth trajectories are driven almost entirely by the pre-existing distribution of religious demand (R), not by market structure, denominational competition, or state regulation. Under a normally distributed population, Christianity plateaus below 5% regardless of competitive advantages. Regulation consistently suppresses growth; persecution filters but does not grow the church. These findings challenge the theoretical basis of high-end projections and suggest that China's religious future depends on demand-side factors that supply-side theory treats as exogenous.

---

## Repository Structure

```
├── model_functions.R          # Core ABM engine (agents, conversion, retention, R dynamics, demography, network)
├── utils.R                    # Plotting functions, scenario presets, color palettes
├── run_batch.R                # Batch runner: 5 scenarios × 4 R distributions
├── Sensitivity_test.R         # Secular cohort factor sensitivity analysis
├── batch_run_whole_codes.R    # Full pipeline: run all scenarios, extract tables and figures
├── tbl_overview.csv           # Summary table (20 rows: peak, final %, SD, persecution)
├── tbl_trajectory.csv         # Christian % at decade intervals (1980–2080)
├── tbl_denominations.csv      # Per-denomination population %, market share, mean R
├── tbl_nc_groups.csv          # Non-Christian group final shares
├── tbl_r_composition.csv      # High/Mid/Low R composition among Christians
├── tbl_secular_sensitivity.csv# Secular cohort sensitivity results
├── tbl_timeseries.csv         # Full time series (all 20 scenarios)
├── scenario_comparison.png    # Faceted comparison plot
└── secular_sensitivity.png    # Secular sensitivity plot
```

## How to Reproduce

**Requirements:** R ≥ 4.1 with `dplyr`, `tidyr`, `ggplot2`, and `parallel`.

```r
# Run everything (20 scenarios × 30 reps + sensitivity analysis)
source("batch_run_whole_codes.R")

# Or run individual components
source("run_batch.R")
results <- run_all_scenarios(n_reps = 30)
plot_scenario_comparison(results)

# Sensitivity analysis only
source("Sensitivity_test.R")
res <- run_secular_sensitivity(n_reps = 30)
plot_secular_sensitivity(res)
```

Full batch run takes approximately 30–60 minutes depending on hardware (parallelized across available cores minus one).

## Model Overview

The model simulates 5,000 agents over 100 years (1980–2080) in half-year timesteps. Each agent carries a religiosity parameter *R* ∈ [−2, 2] that governs conversion susceptibility, retention, and intergenerational transmission. Five Christian denominations (Evangelical, Mainline, Catholic, Charismatic, Other) compete with up to four non-Christian groups (Buddhism, Folk Religion, Islam, Daoism) under varying market conditions.

**Five scenarios** cross two dimensions:

| | Free market | Regulated |
|---|---|---|
| Christians + Nones only | Scenario 1 | — |
| Christians + Passive NCs | Scenario 2 | Scenario 4 |
| Christians + Active NCs | Scenario 3 | Scenario 5 |

Each scenario is run under four *R* distributions (Normal, Bimodal, Right-skewed, Left-skewed) to test sensitivity to demand-side assumptions.

## AI Assistance Disclosure

This paper was edited and all simulation code was developed with the assistance of **Claude Opus 4.5 and Claude Opus 4.6** (Anthropic). The author takes full responsibility for the theoretical framework, model design, parameter choices, interpretation of results, and all claims made in the manuscript.

## Citation

> Li, Ruiqian. 2026. "China is Not the New Rome: An Agent-Based Model Test of the Supply-Side Theory." SocArXiv Preprint. https://doi.org/[DOI]

## License

Code: [MIT License](LICENSE)

Paper: © Ruiqian Li, 2026. All rights reserved.
