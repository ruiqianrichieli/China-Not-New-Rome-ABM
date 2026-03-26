# Verification: 7 Boundary Condition Checks ----
# Runs quick sanity checks on the model mechanics before a full batch.
# Each check isolates one mechanism and confirms it behaves as expected.
# Usage: source("verification.R")

library(dplyr)
source("model_functions.R")
source("utils.R")

cat("\n=== ABM Verification: 7 Boundary Checks ===\n\n")
pass_count <- 0
fail_count <- 0

check <- function(name, condition, diagnostic) {
  status <- if (condition) "PASS" else "FAIL"
  cat(sprintf("[%s] %s | %s\n", status, name, diagnostic))
  if (condition) pass_count <<- pass_count + 1 else fail_count <<- fail_count + 1
}

# Check 1: All R = -2 -> Christianity goes extinct ----
# If nobody has any religious receptivity and R can't increase,
# every Christian should eventually exit. Final % should be ~0.

cat("Check 1: All R = -2 (should go extinct)...\n")
p1 <- get_scenario_params(1, "normal")
p1$n_replications <- 1L
p1$R_mean <- -2; p1$R_sd <- 0
p1$init_R_boost <- 0; p1$init_R_boost_nc <- 0
p1$init_R_strictness_mod <- 0
p1$convert_R_boost <- 0; p1$convert_R_strictness_mod <- 0
p1$convert_R_boost_nc <- 0; p1$cross_convert_R_boost <- 0
p1$offspring_R_boost <- 0; p1$offspring_R_strictness_mod <- 0
p1$R_drift_rate <- 0; p1$R_decay_none <- 0
p1$R_heritability <- 1.0
res1 <- run_replications(p1)
final_chr1 <- tail(res1$summary$christian_pct_mean, 1)
check("All R = -2 -> extinction",
      final_chr1 < 0.001,
      sprintf("Final Christian %% = %.3f%%", final_chr1 * 100))

# Check 2: All R = +2 -> Christianity hits ceiling ----
# Everyone is maximally receptive. Christianity should convert the
# vast majority of the population (>80%).

cat("\nCheck 2: All R = +2 (should hit ceiling)...\n")
p2 <- get_scenario_params(1, "normal")
p2$n_replications <- 1L
p2$R_mean <- 2; p2$R_sd <- 0
p2$init_R_boost <- 0; p2$init_R_boost_nc <- 0
p2$init_R_strictness_mod <- 0
p2$R_drift_rate <- 0; p2$R_decay_none <- 0
p2$R_heritability <- 1.0
res2 <- run_replications(p2)
peak_chr2 <- max(res2$summary$christian_pct_mean)
check("All R = +2 -> high ceiling",
      peak_chr2 > 0.80,
      sprintf("Peak Christian %% = %.1f%%", peak_chr2 * 100))

# Check 3: All evangelism = 0 -> No conversions ----
# With no outreach and demography off, Christianity can only shrink
# via retention exits. Final share should be <= initial share.

cat("\nCheck 3: Zero evangelism (no conversions)...\n")
p3 <- get_scenario_params(1, "right_skewed")
p3$n_replications <- 1L
p3$denom_evangelism <- rep(0, 5)
p3$nc_evangelism <- rep(0, 5)
p3$demography_enabled <- FALSE
res3 <- run_replications(p3)
init_chr3 <- res3$summary$christian_pct_mean[1]
final_chr3 <- tail(res3$summary$christian_pct_mean, 1)
check("Zero evangelism -> no growth from conversion",
      final_chr3 <= init_chr3,
      sprintf("Init = %.2f%%, Final = %.2f%%", init_chr3 * 100, final_chr3 * 100))

# Check 4: Regulation = 1.0 -> Evangelism fully suppressed ----
# Effective evangelism = base * (1 - regulation). At regulation = 1,
# all evangelism zeroes out. Same logic as Check 3 but via regulation.

cat("\nCheck 4: Full regulation (evangelism suppressed)...\n")
p4 <- get_scenario_params(2, "right_skewed")
p4$n_replications <- 1L
p4$regulation_intensity <- 1.0
p4$demography_enabled <- FALSE
res4 <- run_replications(p4)
init_chr4 <- res4$summary$christian_pct_mean[1]
final_chr4 <- tail(res4$summary$christian_pct_mean, 1)
check("Regulation = 1.0 -> no conversion growth",
      final_chr4 <= init_chr4 + 0.001,
      sprintf("Init = %.2f%%, Final = %.2f%%", init_chr4 * 100, final_chr4 * 100))

# Check 5: Demography disabled -> population size unchanged ----
# With demography off, no agents are replaced. The data.frame should
# still have exactly n_agents rows at the end.

cat("\nCheck 5: No demography (population stable, only conversion/retention)...\n")
p5 <- get_scenario_params(1, "right_skewed")
p5$n_replications <- 1L
p5$demography_enabled <- FALSE
sim5 <- run_simulation(p5)
n_agents <- nrow(sim5$final_agents)
check("Demography off -> population size unchanged",
      n_agents == p5$n_agents,
      sprintf("Expected %d agents, got %d", p5$n_agents, n_agents))

# Check 6: Persecution threshold = 0 -> always active ----
# A threshold of 0 means any Christian share > 0 triggers persecution.
# Since we start with 0.5% Christian, it should be active every step.

cat("\nCheck 6: Persecution threshold = 0 (always active)...\n")
p6 <- get_scenario_params(4, "right_skewed")
p6$n_replications <- 1L
p6$persecution_threshold <- 0
res6 <- run_replications(p6)
all_persecuted <- all(res6$summary$persecution_pct == 1)
check("Threshold = 0 -> persecution always active",
      all_persecuted,
      sprintf("Persecution active in %d/%d timesteps",
              sum(res6$summary$persecution_pct == 1),
              nrow(res6$summary)))

# Check 7: Single Charismatic R=2 exit rate ----
# Analytical check. Charismatic strictness = 0.9, base_exit_high = 0.005,
# retention modifier = 0.6. So exit rate = 0.005 * (1 - 0.9*0.6) = 0.0023.
# We put 10k agents in Charismatic at R=2, freeze everything else, and
# see if the first-step exit rate matches within sampling noise (+/-0.005).

cat("\nCheck 7: Single Charismatic R=2 exit rate...\n")
expected_exit <- 0.005 * (1 - 0.9 * 0.6)
p7 <- get_default_params()
p7$n_agents <- 10000L
p7$n_replications <- 1L
p7$denom_initial_pct <- c(0, 0, 0, 1.0, 0)
p7$n_nonchristian <- 0L
p7$denom_evangelism <- rep(0, 5)
p7$R_mean <- 2; p7$R_sd <- 0
p7$init_R_boost <- 0; p7$init_R_strictness_mod <- 0
p7$R_drift_rate <- 0; p7$R_decay_none <- 0
p7$demography_enabled <- FALSE
p7$network_enabled <- FALSE
p7$base_convert_prob <- 0
sim7 <- run_simulation(p7)
r7 <- sim7$results
n_init <- r7$charismatic_n[1]
n_after1 <- r7$charismatic_n[2]
observed_exit <- (n_init - n_after1) / n_init
check("Charismatic R=2 exit rate ~ 0.0023/step",
      abs(observed_exit - expected_exit) < 0.005,
      sprintf("Expected %.4f, observed %.4f", expected_exit, observed_exit))

# Summary ----

cat(sprintf("\n=== Results: %d PASS, %d FAIL out of 7 ===\n",
            pass_count, fail_count))