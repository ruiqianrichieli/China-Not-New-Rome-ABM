# Online Supplement Index

**"China is Not the New Rome: An Agent-Based Model Test of the Supply-Side Theory"**

This document catalogs all supplementary materials accompanying the paper. Materials are organized into four supplements.

## Supplement A: ODD Protocol

**File:** `ODD_protocol.md`

Full model description following the ODD protocol (Grimm et al. 2020). Covers purpose, entities and state variables, process overview, design concepts, initialization, input data, all submodel equations, simulation experiment design, and verification results.

## Supplement B: Output Tables

All tables are in CSV format in the `tables/` directory. Values represent means across 30 replications unless otherwise noted. All sensitivity analyses are conducted under Scenario 4 (regulated, passive NC) with right-skewed R distribution unless otherwise noted.

### Baseline Results

| File | Description | Rows | Key Columns |
|------|-------------|------|-------------|
| `tbl_overview.csv` | Summary of all 20 baseline conditions (5 scenarios × 4 R distributions). Reports initial, peak, and final Christian %, peak year, final NC/None shares, mean R, convert share, and whether persecution ever activated. | 20 | Peak_Chr, Final_Chr, Final_R_Mean, Final_Convert_Pct |
| `tbl_trajectory.csv` | Christian population share at decadal intervals (1980–2080) for all 20 conditions. | 20 | Y1980 through Y2080 |
| `tbl_timeseries.csv` | Full half-year time series for all 20 conditions. Includes mean, SD, and 10th–90th percentile bands for Christian share, plus NC share, None share, mean R, convert share, and persecution status. | 4,000 | christian_pct_mean, christian_pct_sd, christian_pct_lo, christian_pct_hi |
| `tbl_r_composition.csv` | R composition among Christians at 2080: percentage in High-R (>1.0), Mid-R (0–1.0), and Low-R (≤0) categories, plus mean R. All 20 conditions. | 20 | High_R_Pct, Mid_R_Pct, Low_R_Pct, Mean_R |
| `tbl_denominations.csv` | Denominational composition at 2080: population percentage, within-Christian share, and mean R for each of the 5 denominations. All 20 conditions. | 20 | Evangelical_Share, Charismatic_Share, etc. |
| `tbl_nc_groups.csv` | Non-Christian group composition at 2080: population percentage for Buddhism, Folk Religion, Islam, and Daoism. Scenarios 2–5 only. | 16 | Buddhism_Pct, Folk Religion_Pct, Islam_Pct, Daoism_Pct |

### Sensitivity Analyses

All sensitivity tables share a common structure: `param_label`, `param_value`, `peak_pct` (peak Christian %), `peak_year`, `final_pct` (Christian % at 2080), and `final_R_mean`. Unless noted, all tests use Scenario 4 (regulated, passive NC) with right-skewed R.

#### Tier 1: Supply-Side Mechanisms

| File | Parameter | Range Tested | Key Finding |
|------|-----------|-------------|-------------|
| `tbl_solidarity_sensitivity.csv` | Solidarity boost | 0 to 2.0 | Effect saturates at 0.25; further increases produce no additional growth (final: 6.8% to 9.2%) |
| `tbl_deterrence_sensitivity.csv` | Deterrence penalty | 0 to −1.5 | Zero detectable effect at all levels (final: 9.2% at every level) |
| `tbl_beta_sensitivity.csv` | Base conversion probability β | 0.1 to 0.9 | Largest Tier 1 effect (final: 1.2% to 55.6%); baseline 0.3 is generous |
| `tbl_switching_cost_sensitivity.csv` | Switching cost multiplier | 0× to 2× | Modest effect (final: 7.6% to 12.4%) |

#### Tier 2: Structural Assumptions

| File | Parameter | Range Tested | Key Finding |
|------|-----------|-------------|-------------|
| `tbl_R_decay_sensitivity.csv` | R decay rate δ | 0 to 0.03 | Largest effect of any parameter (final: 1.4% to 51.7%); demand-side parameter |
| `tbl_evangelism_sensitivity.csv` | Evangelism intensity multiplier | 0.5× to 3× | Large range (final: 1.1% to 60.4%) |
| `tbl_regulation_intensity_sensitivity.csv` | Regulation intensity | 0.2 to 1.0 | Monotonic suppression (final: 0.1% to 33.8%) |
| `tbl_network_degree_sensitivity.csv` | Network degree k | 5 to 30 | Moderate effect under right-skewed R (final: 2.9% to 13.3%); near-zero under other distributions. Includes all 4 R distributions. |
| `tbl_initial_share_sensitivity.csv` | Initial Christian share | 0.25% to 3% | Moderate effect (final: 5.4% to 17.0%) |
| `tbl_persecution_threshold_sensitivity.csv` | Persecution threshold | 2% to 30% | Moderate effect (final: 6.7% to 10.4%); ceiling above 25% |
| `tbl_persecution_impact_chr_sensitivity.csv` | Persecution impact on Christians | 0.1 to 0.9 | Moderate effect (final: 4.2% to 12.9%) |
| `tbl_persecution_impact_nc_sensitivity.csv` | Persecution impact on NC groups | 0 to 0.5 | Zero detectable effect (final: 9.2% at all levels) |
| `tbl_cross_convert_sensitivity.csv` | Cross-religion conversion probability | 0.05 to 0.4 | Moderate effect (final: 5.4% to 22.3%) |
| `tbl_R_drift_sensitivity.csv` | R drift rate γ | 0 to 0.1 | Small effect (final: 7.8% to 10.4%) |
| `tbl_population_sensitivity.csv` | Population size N | 5,000 to 20,000 | No meaningful variation (final: 9.0% to 9.2% under right-skewed R). Includes all 4 R distributions. |
| `tbl_homophily_sensitivity.csv` | Network homophily | 0.2 to 0.7 | Small effect (final: 8.3% to 10.9%) |

#### Secular Sensitivity and Mega-Test

| File | Description | Key Finding |
|------|-------------|-------------|
| `tbl_secular_sensitivity.csv` | Secular cohort factor: 0% to 80% transmission reduction | Final: 4.3% (80% loss) to 11.2% (no loss). All levels converge by 2020; diverge afterward. |
| `tbl_mega_test.csv` | All parameters simultaneously maximized, all 4 R distributions | Normal: 25.0%; Bimodal: 29.6%; Right-skewed: 74.8%; Left-skewed: 0% (extinct) |

## Supplement C: Figures

All figures are PNG files (300 DPI) in the `figures/` directory.

### Main Text Figures

| File | Description |
|------|-------------|
| `scenario_comparison.png` | Christian share trajectories for all 20 conditions (5 scenarios × 4 R distributions), 2×2 panel by R distribution. Shaded bands show 10th–90th percentile across 30 replications. |
| `secular_sensitivity.png` | Secular cohort factor sensitivity: 5 levels of intergenerational transmission loss under Scenario 4 with right-skewed R. |
| `tier1_panel.png` | Four-panel display of Tier 1 parameter sensitivity: solidarity, deterrence, β, and switching cost. |
| `mega_test.png` | Mega-test results across all 4 R distributions with all parameters maximized. |
| `convert_share.png` | Convert share (proportion of Christians who are first-generation converts) over time, all scenarios. |
| `robustness_panel.png` | Multi-panel robustness summary across selected sensitivity tests. |

### Individual Sensitivity Plots

Each plot shows the Christian share trajectory under varying levels of one parameter, with shaded 10th–90th percentile bands across 30 replications. All under Scenario 4 (regulated, passive NC) with right-skewed R unless noted.

| File | Parameter Varied |
|------|-----------------|
| `solidarity_sensitivity.png` | Solidarity boost (0 to 2.0) |
| `deterrence_sensitivity.png` | Deterrence penalty (0 to −1.5) |
| `beta_sensitivity.png` | Base conversion probability β (0.1 to 0.9) |
| `switching_cost_sensitivity.png` | Switching cost multiplier (0× to 2×) |
| `evangelism_sensitivity.png` | Evangelism intensity (0.5× to 3×) |
| `regulation_intensity_sensitivity.png` | Regulation intensity (0.2 to 1.0) |
| `network_degree_sensitivity.png` | Network degree k (5 to 30) |
| `homophily_sensitivity.png` | Network homophily (0.2 to 0.7) |
| `population_sensitivity.png` | Population size N (5k to 20k) |
| `initial_share_sensitivity.png` | Initial Christian share (0.25% to 3%) |
| `persecution_threshold_sensitivity.png` | Persecution threshold (2% to 30%) |
| `persecution_impact_chr_sensitivity.png` | Persecution impact on Christians (0.1 to 0.9) |
| `persecution_impact_nc_sensitivity.png` | Persecution impact on NC (0 to 0.5) |
| `R_decay_sensitivity.png` | R decay rate δ (0 to 0.03) |
| `R_drift_sensitivity.png` | R drift rate γ (0 to 0.1) |
| `cross_convert_sensitivity.png` | Cross-conversion probability (0.05 to 0.4) |
| `best_case_persecution.png` | Best-case persecution scenario vs. baseline under regulation |

## Supplement D: Verification Results

**Code:** `verification.R` (in repository root)

Seven boundary-condition checks confirm correct implementation of all core mechanisms. Each test isolates one mechanism under an extreme condition where the expected outcome is analytically known, then checks whether the simulation produces it. All seven tests pass. See the ODD protocol (Supplement A, Section 9) for full details.

| # | Test | Expected Outcome | Status |
|---|------|-----------------|--------|
| 1 | All R = −2 | Christianity goes extinct (< 0.001%) | PASS |
| 2 | All R = +2 | Christianity exceeds 80% | PASS |
| 3 | All evangelism = 0 | No conversion growth | PASS |
| 4 | Regulation = 1.0 | Evangelism fully suppressed | PASS |
| 5 | Demography disabled | Population size unchanged at N = 5,000 | PASS |
| 6 | Persecution threshold = 0% | Persecution active in 100% of timesteps | PASS |
| 7 | Charismatic R = 2.0 exit rate | Observed ≈ 0.0023/step (within ±0.005 of analytical expectation) | PASS |
