# ODD Protocol: Agent-Based Model of Christian Growth in China

Following Grimm et al. (2020), "The ODD Protocol for Describing Agent-Based and Other Simulation Models: A Second Update to Improve Clarity, Replication, and Structural Realism." *JASSS* 23(2):7.

## 1. Purpose and Patterns

### 1.1 Purpose

The model tests whether the core mechanisms of the rational choice theory of religion (Stark and Finke 2000) and the strict church thesis (Iannaccone 1994), when formalized and given every structural advantage, can produce the sustained 7–10% annual Christian growth predicted for China by Yang (2016a) and Stark and Wang (2015). The model is designed for theory-testing rather than forecasting: its goal is to determine whether the theory's own mechanisms are sufficient to generate the claimed outcomes under maximally favorable conditions.

### 1.2 Patterns

The model is evaluated against three empirical patterns:

1. Christian population share at 2020: multiple independent sources estimate 2–7% (Hackett and Tong 2025; Zhou, Lai, and Li 2024; Johnson and Zurlo 2020).
2. Stagnation or decline in Christian affiliation across successive birth cohorts (Zhou, Lai, and Li 2024).
3. A high proportion of first-generation converts among current Chinese Christians, consistent with a young religious community under weak intergenerational transmission.

## 2. Entities, State Variables, and Scales

### 2.1 Entities

**Agents.** Each agent represents an individual in the population. Agents carry the following state variables:

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `id` | Integer | 1 to N | Unique identifier |
| `R` | Continuous | [−2, 2] | Religious receptivity (latent openness to organized religion) |
| `identity` | Categorical | 10 levels | Current religious affiliation: one of 5 Christian denominations, 4 NC religions, or None |
| `source` | Categorical | "born", "convert", NA | How the agent acquired current religion |
| `tenure` | Integer | ≥ 0 | Half-year timesteps since joining current group |

**Christian denominations** (5): Evangelical, Mainline (Three-Self), Catholic, Charismatic, Other Christian. Each denomination is characterized by:

| Parameter | Evangelical | Mainline | Catholic | Charismatic | Other |
|-----------|------------|----------|----------|-------------|-------|
| Entry strictness | 0.2 | 0.2 | 0.4 | 0.8 | 0.3 |
| Retention strictness | 0.7 | 0.2 | 0.5 | 0.9 | 0.3 |
| Evangelism intensity | 0.9 | 0.2 | 0.3 | 0.9 | 0.4 |
| Initial share (1980) | 0.1% | 0.1% | 0.1% | 0.1% | 0.1% |

**Non-Christian (NC) religions** (4): Buddhism, Folk Religion, Islam, Daoism. Each carries strictness, transmission rate, and switching cost parameters.

| Parameter | Buddhism | Folk Religion | Islam | Daoism |
|-----------|----------|---------------|-------|--------|
| Strictness | 0.3 | 0.1 | 0.9 | 0.2 |
| Evangelism | 0.05 | 0.00 | 0.00 | 0.00 |
| Active recruitment | No | No | No | No |
| Initial share (1980) | 8% | 20% | 1.5% | 3% |
| Transmission rate | 0.60 | 0.70 | 0.95 | 0.40 |
| Switching cost | 0.3 | 0.2 | 2.0 | 0.2 |

### 2.2 Scales

- **Temporal:** 100 simulated years (1980–2080) in half-year timesteps (200 timesteps total).
- **Spatial:** No explicit spatial grid. Agents interact through a social network (see Section 2.3).
- **Population:** N = 5,000 agents (baseline). Sensitivity analysis confirms robustness at N = 10,000 and 20,000.

### 2.3 Network

Agents are embedded in an undirected social network with mean degree k = 15 ties per agent (baseline). The network is initialized as a custom directed random graph with homophily constraints, then symmetrized:

- Christian agents: 50% of ties go to co-religionists (any Christian denomination).
- NC agents: 25% of ties go to agents of the same NC religion.
- None agents: no homophily constraint.
- Remaining ties drawn uniformly from the population.

On conversion, agents gain co-religionist ties and lose some out-group ties, producing endogenous clustering over time.

## 3. Process Overview and Scheduling

Each half-year timestep executes seven processes in fixed order:

1. **Persecution check:** If Christian share > persecution threshold (default 5%), persecution activates.
2. **Conversion (None → Religion):** Unaffiliated agents exposed to religious groups; convert if R exceeds entry threshold.
3. **Cross-religion conversion (NC → Christian):** NC members may convert to Christianity with additional switching cost barrier.
4. **Inter-denominational switching:** Christians move between denominations based on R-strictness fit.
5. **Retention:** Religious agents may exit to None based on R category and group strictness.
6. **R dynamics:** Secular erosion for unaffiliated; social reinforcement for religious; persecution effects.
7. **Demography:** 2% agent replacement per timestep with probabilistic religion inheritance.

All processes are executed synchronously within each timestep (agents updated simultaneously within each process, but processes execute sequentially).

## 4. Design Concepts

### 4.1 Basic Principles

The model operationalizes two theoretical frameworks. The rational choice theory (Stark and Finke 2000) is implemented through competitive evangelism, market structure, and regulation effects. The strict church thesis (Iannaccone 1994) is implemented through denomination-specific strictness parameters that govern entry, retention, and R dynamics.

### 4.2 Emergence

Population-level outcomes (Christian share trajectories, denominational composition, R distribution shifts) emerge from individual-level conversion, retention, and R dynamics. No aggregate-level growth rate is imposed.

### 4.3 Adaptation

Agents do not optimize or plan. Their behavior is probabilistic: conversion probability depends on R, exposure, and group thresholds. Inter-denominational switching represents implicit adaptation as agents drift toward groups that match their R level.

### 4.4 Objectives

Agents have no explicit utility function. R serves as a latent trait governing susceptibility to religious affiliation, not as a consciously pursued goal.

### 4.5 Learning

No individual learning. R changes through social reinforcement (drift toward co-religionist mean), secular erosion (for unaffiliated), and persecution effects. These represent social influence rather than learning.

### 4.6 Prediction

Agents do not predict future states. All decisions are based on current R values and immediate network exposure.

### 4.7 Sensing

Agents sense the religious identities of their network neighbors. Conversion exposure is local (network-based) rather than global (mean-field).

### 4.8 Interaction

Direct interaction occurs through network ties. Evangelistic exposure is proportional to the fraction of network neighbors belonging to each religious group, weighted by group evangelism intensity.

### 4.9 Stochasticity

Stochastic elements include: R distribution initialization, agent assignment to groups, conversion decisions (probabilistic given exposure and R gap), retention exits, inter-denominational switching, demographic replacement, and network tie formation. Each scenario is run for 30 replications with different random seeds.

### 4.10 Collectives

Christian denominations and NC religions function as implicit collectives. They share strictness parameters and members' R values drift toward group means through social reinforcement.

### 4.11 Observation

At each timestep, the model records: Christian population share (mean, SD, 10th–90th percentile across replications), NC and None shares, mean R among Christians, convert share (proportion of Christians who entered via conversion rather than birth), and whether persecution is active.

## 5. Initialization

Agents are initialized to represent China circa 1980:

- 0.5% Christian (equally split across 5 denominations: 0.1% each)
- 34.5% non-Christian (Buddhism 8%, Folk Religion 20%, Islam 1.5%, Daoism 3%, Other 2%)
- 65% unaffiliated (None)

R values are drawn from one of four distributions:

| Distribution | Parameters | Interpretation |
|-------------|------------|----------------|
| Normal | mean = 0, SD = 1 | Neutral population |
| Bimodal | modes at −0.8 and +0.8, SD = 0.5 | Polarized society |
| Right-skewed | Beta(5, 2) rescaled to [−2, 2] | Religiously favorable (supply-side assumption) |
| Left-skewed | Beta(2, 5) rescaled to [−2, 2] | Secularized population |

Religious agents receive initial R boosts: Christians get +0.2 + (strictness × 0.2); NC agents get +0.15. All R values are clamped to [−2, 2].

## 6. Input Data

The model uses no external time-varying input data. All parameters are set at initialization and remain constant (except the secular cohort factor, which activates at simulation year 2012).

## 7. Submodels

### 7.1 Persecution Check

Persecution activates when Christian population share exceeds the persecution threshold θ (default = 0.05):

```
persecution_active = (christian_share > θ)
```

When active, persecution modifies effective evangelism and R dynamics (see 7.6).

### 7.2 Conversion (None → Religion)

For each unaffiliated agent *i* with network neighbors:

**Exposure** to group *g*:

```
exposure(i, g) = (n_neighbors_in_g / n_total_neighbors) × evangelism(g) × (1 − regulation)
```

If persecution is active, evangelism is further reduced:

```
effective_evangelism(g) = evangelism(g) × (1 − regulation) × (1 − persecution_impact)
```

**Conversion threshold** for group *g*:

```
threshold(g) = base_threshold + entry_strictness(g) × strictness_modifier
```

Default: base_threshold = 0.3, strictness_modifier = 0.8.

**Conversion probability** (if R(i) > threshold(g)):

```
P(convert to g) = base_convert_prob × (1 + R(i) − threshold(g)) × exposure(i, g)
```

Default: base_convert_prob = 0.3.

Total conversion probability is capped at 1.0. If multiple groups are eligible, the agent converts to one group drawn proportionally to the per-group probabilities. Converts receive an R boost:

```
R_boost = convert_R_boost + strictness(g) × convert_R_strictness_mod
```

Default: convert_R_boost = 0.1, convert_R_strictness_mod = 0.1.

### 7.3 Cross-Religion Conversion (NC → Christian)

Same mechanism as 7.2 but applied to NC agents converting to Christian denominations, with an additional switching cost barrier:

```
effective_threshold(g, j) = threshold(g) + switching_cost(j)
```

where *j* is the agent's current NC group. Cross-conversion probability uses a separate base rate (default: cross_convert_prob = 0.15). The reverse direction (Christian → NC) is not modeled.

### 7.4 Inter-Denominational Switching

Christian agents may switch denominations based on the fit between their R and each denomination's strictness:

- **Upward switching** (to stricter denomination): occurs when R(i) > threshold(target) + up_buffer (0.2). Probability proportional to target denomination's share × switch_rate (0.05).
- **Downward switching** (to more lenient denomination): occurs when R(i) < threshold(current) − down_buffer (0.3). Rate multiplied by down_rate_multiplier (2.0).

### 7.5 Retention

Religious agents exit to None each timestep with probability based on R category and group strictness:

```
exit_rate = base_exit(R_category) × (1 − strictness(g) × retention_modifier)
```

| R Category | Condition | Base Exit Rate (Christian) | Base Exit Rate (NC) |
|-----------|-----------|---------------------------|---------------------|
| High | R > 1.0 | 0.005 | 0.003 |
| Mid | 0 < R ≤ 1.0 | 0.02 | 0.015 |
| Low | R ≤ 0 | 0.08 | 0.05 |

Retention modifier (default) = 0.6. NC agents with R > 0 receive an additional stickiness factor (0.5) reducing exit rates. Exiting agents receive an R penalty of −0.3.

### 7.6 R Dynamics

Three components:

**Secular erosion (unaffiliated agents):**

```
R(t+1) = R(t) − δ
```

Default: δ = 0.01 per half-year timestep.

**Social reinforcement (religious agents):**

With network enabled, Christian agents' R drifts entirely toward same-religion network neighbor mean (weight = 1.0):

```
target = neighbor_mean_R (same religion)
R(t+1) = R(t) + γ × (target − R(t))
```

NC agents use a blended target (weight = 0.5 neighbor mean, 0.5 global group mean):

```
target = w × neighbor_mean + (1 − w) × global_group_mean
```

Default: γ = 0.03, w = 0.5.

**Persecution effects (when active, Christian agents only):**

```
If R(i) ≤ 0 (low-R):   R(i) += deterrence_penalty    (default: −0.5)
If R(i) > 1.0 (high-R): R(i) += solidarity_boost      (default: +0.5)
```

All R values clamped to [−2, 2] after updates.

### 7.7 Demography

Each timestep, 2% of agents are randomly selected for replacement (turnover_rate = 0.02), producing approximately a 25-year generational cycle.

**Religion inheritance:** Children inherit their parent's religion probabilistically:

```
transmission_prob = base_transmission + strictness(g) × transmission_modifier
```

Default: base_transmission = 0.8, transmission_modifier = 0.3.

**Secular cohort factor:** After simulation year 2012, transmission probability is multiplied by the secular cohort factor (default: 0.8, representing a 20% reduction). This captures state-imposed constraints on religious socialization and broader secularization forces.

**R inheritance:**

```
R_child = heritability × R_parent + (1 − heritability) × rnorm(R_mean, R_sd)
```

Default: heritability = 0.8. Children inheriting a religion receive an R boost: +0.15 + (strictness × 0.1). Children who do not inherit become None with source = NA.

**NC transmission rates** are group-specific (Buddhism 0.60, Folk Religion 0.70, Islam 0.95, Daoism 0.40) and also subject to the secular cohort factor after 2012.

## 8. Simulation Experiments

### 8.1 Baseline Design

5 scenarios × 4 R distributions = 20 conditions, each run for 30 replications. See Table 2 in the main text for scenario definitions.

### 8.2 Secular Sensitivity Analysis

The secular cohort factor is varied across 5 levels (0%, 20%, 40%, 60%, 80% reduction) under Scenario 4 with right-skewed R. 30 replications per level.

### 8.3 Parameter Sensitivity Analysis

18 parameters tested individually under Scenario 4 with right-skewed R:

**Tier 1 (supply-side mechanisms):** solidarity boost (0 to 2.0), deterrence penalty (0 to −1.5), base conversion probability β (0.1 to 0.9), switching cost multiplier (0× to 2×).

**Tier 2 (structural assumptions):** R decay δ (0 to 0.03), evangelism intensity (0.5× to 3×), regulation intensity (0.2 to 1.0), network degree k (5 to 30), initial Christian share (0.25% to 3%), persecution threshold (2% to 30%), persecution impact on Christians (0.1 to 0.9), persecution impact on NC (0 to 0.5), cross-conversion probability (0.05 to 0.4), R drift rate γ (0 to 0.1), population size N (5,000 to 20,000), network homophily (0.2 to 0.7).

### 8.4 Mega-Test

All adjustable parameters simultaneously set to their most Christianity-favorable values and run across all 4 R distributions.

## 9. Verification

Seven boundary-condition tests confirm correct implementation (see `verification.R`):

| Check | Condition | Expected | Result |
|-------|-----------|----------|--------|
| 1 | All R = −2 | Christianity extinct (< 0.001%) | PASS |
| 2 | All R = +2 | Christianity > 80% | PASS |
| 3 | All evangelism = 0 | No conversion growth | PASS |
| 4 | Regulation = 1.0 | Evangelism fully suppressed | PASS |
| 5 | Demography off | Population size unchanged | PASS |
| 6 | Persecution threshold = 0 | Active 100% of timesteps | PASS |
| 7 | Charismatic R = 2 exit rate | ≈ 0.0023/step (±0.005) | PASS |

## References

- Grimm, V., et al. 2020. "The ODD Protocol for Describing Agent-Based and Other Simulation Models." *JASSS* 23(2):7.
- Iannaccone, L. R. 1994. "Why Strict Churches Are Strong." *AJS* 99(5):1180–1211.
- Stark, R. and R. Finke. 2000. *Acts of Faith.* UC Press.
- Stark, R. and X. Wang. 2015. *A Star in the East.* Templeton.
- Yang, F. 2016a. "Exceptionalism or Chinamerica." *JSSR* 55(1):7–22.
