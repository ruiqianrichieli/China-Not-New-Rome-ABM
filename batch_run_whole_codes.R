# Run batch and extract results
# 20 runs: 5 scenarios × 4 R distributions
# + secular sensitivity + Tier 1-3 robustness + mega-test


# Setup----
# Sources all dependencies and runs the full 20-cell baseline (5 scenarios x 4 R dists).

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}
source("run_batch.R")

cat("Starting 20 scenarios x 30 reps (parallel)\n")
cat("Cores:", max(1L, parallel::detectCores() - 1L), "\n\n")

results <- run_all_scenarios(n_reps = 30)
saveRDS(results, "scenario_results.rds")


# To reload without re-running:
# source("run_batch.R")
# results <- readRDS("scenario_results.rds")


# Helpers----
# Shared labels and denomination keys used across all extraction blocks below.

dists <- c("normal", "bimodal", "right_skewed", "left_skewed")
dist_labels <- c(normal = "Normal", bimodal = "Bimodal",
                 right_skewed = "Right-skewed", left_skewed = "Left-skewed")
sc_labels <- c(
  "1: Chr + Nones (Free)", "2: Chr + Passive NC (Free)",
  "3: Chr + Active NC (Free)", "4: Chr + Passive NC (Reg)",
  "5: Chr + Active NC (Reg)")
denom_names <- c("Evangelical", "Mainline", "Catholic", "Charismatic", "Other Christian")
denom_keys <- c("evangelical", "mainline", "catholic", "charismatic", "other_christian")


# Scenario summary function----
# Builds the 20-row overview table: init/peak/final Christian %, peak year,
# final NC/None shares, mean R, convert share, and whether persecution ever fired.

summarize_scenarios <- function(results_list) {
  rows <- list()
  for (d in dists) {
    for (s in 1:5) {
      key <- paste0("s", s, "_", d)
      res <- results_list[[key]]
      if (is.null(res)) next
      sm <- res$summary
      
      final <- tail(sm, 1)
      peak_idx <- which.max(sm$christian_pct_mean)
      
      rows[[length(rows) + 1]] <- data.frame(
        Scenario = sc_labels[s],
        R_Dist = dist_labels[d],
        Init_Chr = round(sm$christian_pct_mean[1] * 100, 2),
        Peak_Chr = round(sm$christian_pct_mean[peak_idx] * 100, 2),
        Peak_Year = floor(sm$time[peak_idx]),
        Final_Chr = round(final$christian_pct_mean * 100, 2),
        Final_Chr_SD = round(final$christian_pct_sd * 100, 2),
        Final_NC = round(final$total_nc_pct_mean * 100, 2),
        Final_None = round(final$none_pct_mean * 100, 2),
        Final_R_Mean = round(final$christian_R_mean, 3),
        Final_Convert_Pct = round(final$christian_convert_pct_mean * 100, 1),
        Persecution_Ever = ifelse(max(sm$persecution_pct) > 0, "Yes", "No"),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}


# Sensitivity helper: run, save, summarize----
# Wrapper that runs a sensitivity test, saves the RDS/PNG/CSV triplet,
# and returns the results + summary table. Keeps the main script DRY.

run_save_sensitivity <- function(run_fn, plot_fn, prefix, n_reps = 30, ...) {
  cat("\n=== Running:", prefix, "===\n\n")
  res <- run_fn(n_reps = n_reps, ...)
  saveRDS(res, paste0(prefix, "_results.rds"))
  ggsave(paste0(prefix, ".png"), plot_fn(res), width = 10, height = 6, dpi = 300)
  tbl <- summarize_sensitivity(res)
  write.csv(tbl, paste0("tbl_", prefix, ".csv"), row.names = FALSE)
  cat("  Saved:", prefix, "\n")
  list(results = res, table = tbl)
}

run_save_sensitivity_by_dist <- function(run_fn, plot_fn, prefix, n_reps = 30, ...) {
  cat("\n=== Running:", prefix, "===\n\n")
  res <- run_fn(n_reps = n_reps, ...)
  saveRDS(res, paste0(prefix, "_results.rds"))
  ggsave(paste0(prefix, ".png"), plot_fn(res), width = 14, height = 8, dpi = 300)
  tbl <- summarize_sensitivity(res)
  write.csv(tbl, paste0("tbl_", prefix, ".csv"), row.names = FALSE)
  cat("  Saved:", prefix, "\n")
  list(results = res, table = tbl)
}


# 1. Comparison plot----

ggsave("scenario_comparison.png", plot_scenario_comparison(results),
       width = 14, height = 8, dpi = 150)

ggsave("convert_share.png", plot_convert_share(results),
       width = 14, height = 8, dpi = 150)


# 2. Overall summary table (20 rows)----

tbl_overview <- summarize_scenarios(results)
write.csv(tbl_overview, "tbl_overview.csv", row.names = FALSE)


# 3. Denomination breakdown----

rows_denom <- list()
for (d in dists) {
  for (s in 1:5) {
    key <- paste0("s", s, "_", d)
    res <- results[[key]]
    if (is.null(res)) next
    ar <- res$all_runs
    final <- ar |> filter(time == max(time))
    
    chr_total <- mean(final$christian_pct)
    if (chr_total == 0) chr_total <- 1
    
    row <- data.frame(Scenario = sc_labels[s], R_Dist = dist_labels[d])
    for (i in seq_along(denom_keys)) {
      col_pct <- paste0(denom_keys[i], "_pct")
      col_R <- paste0(denom_keys[i], "_R_mean")
      row[[paste0(denom_names[i], "_Pct")]] <- round(mean(final[[col_pct]]) * 100, 2)
      row[[paste0(denom_names[i], "_Share")]] <- round(mean(final[[col_pct]]) / chr_total * 100, 1)
      row[[paste0(denom_names[i], "_R")]] <- round(mean(final[[col_R]], na.rm = TRUE), 3)
    }
    rows_denom[[length(rows_denom) + 1]] <- row
  }
}
tbl_denom <- do.call(rbind, rows_denom)
write.csv(tbl_denom, "tbl_denominations.csv", row.names = FALSE)


# 4. NC group breakdown----

nc_names <- c("Buddhism", "Folk Religion", "Islam", "Daoism")
rows_nc <- list()
for (d in dists) {
  for (s in 2:5) {
    key <- paste0("s", s, "_", d)
    res <- results[[key]]
    if (is.null(res)) next
    ar <- res$all_runs
    final <- ar |> filter(time == max(time))
    
    row <- data.frame(Scenario = sc_labels[s], R_Dist = dist_labels[d])
    for (j in 1:4) {
      col <- paste0("nc_", j, "_pct")
      row[[paste0(nc_names[j], "_Pct")]] <- round(mean(final[[col]]) * 100, 2)
    }
    row$Total_NC <- round(mean(final$total_nc_pct) * 100, 2)
    rows_nc[[length(rows_nc) + 1]] <- row
  }
}
tbl_nc <- do.call(rbind, rows_nc)
write.csv(tbl_nc, "tbl_nc_groups.csv", row.names = FALSE)


# 5. R composition----

rows_rcomp <- list()
for (d in dists) {
  for (s in 1:5) {
    key <- paste0("s", s, "_", d)
    res <- results[[key]]
    if (is.null(res)) next
    ar <- res$all_runs
    final <- ar |> filter(time == max(time))
    
    rows_rcomp[[length(rows_rcomp) + 1]] <- data.frame(
      Scenario = sc_labels[s], R_Dist = dist_labels[d],
      High_R_Pct = round(mean(final$christian_R_high_pct, na.rm = TRUE) * 100, 1),
      Mid_R_Pct = round(mean(final$christian_R_mid_pct, na.rm = TRUE) * 100, 1),
      Low_R_Pct = round(mean(final$christian_R_low_pct, na.rm = TRUE) * 100, 1),
      Mean_R = round(mean(final$christian_R_mean, na.rm = TRUE), 3)
    )
  }
}
tbl_rcomp <- do.call(rbind, rows_rcomp)
write.csv(tbl_rcomp, "tbl_r_composition.csv", row.names = FALSE)


# 6. Growth trajectory----

key_years <- c(1980, 1990, 2000, 2010, 2020, 2030, 2040, 2050, 2060, 2070, 2080)
rows_traj <- list()
for (d in dists) {
  for (s in 1:5) {
    key <- paste0("s", s, "_", d)
    res <- results[[key]]
    if (is.null(res)) next
    sm <- res$summary
    
    row <- data.frame(Scenario = sc_labels[s], R_Dist = dist_labels[d])
    for (yr in key_years) {
      closest <- sm[which.min(abs(sm$time - yr)), ]
      row[[paste0("Y", yr)]] <- round(closest$christian_pct_mean * 100, 2)
    }
    rows_traj[[length(rows_traj) + 1]] <- row
  }
}
tbl_trajectory <- do.call(rbind, rows_traj)
write.csv(tbl_trajectory, "tbl_trajectory.csv", row.names = FALSE)


# 7. Full time series----

rows_ts <- list()
for (d in dists) {
  for (s in 1:5) {
    key <- paste0("s", s, "_", d)
    res <- results[[key]]
    if (is.null(res)) next
    rows_ts[[length(rows_ts) + 1]] <- res$summary |>
      mutate(Scenario = sc_labels[s], R_Dist = dist_labels[d])
  }
}
tbl_timeseries <- do.call(rbind, rows_ts)
write.csv(tbl_timeseries, "tbl_timeseries.csv", row.names = FALSE)


# 8. Secular sensitivity----

cat("\n=== Running Secular Sensitivity ===\n\n")

sec_results <- run_secular_sensitivity(n_reps = 30)
saveRDS(sec_results, "secular_sensitivity_results.rds")

ggsave("secular_sensitivity.png", plot_secular_sensitivity(sec_results),
       width = 10, height = 6, dpi = 300)

tbl_secular <- summarize_secular_sensitivity(sec_results)
write.csv(tbl_secular, "tbl_secular_sensitivity.csv", row.names = FALSE)


# 9. Tier 1: Solidarity Boost----

t1_sol <- run_save_sensitivity(
  run_solidarity_sensitivity, plot_solidarity_sensitivity, "solidarity_sensitivity")

# 10. Tier 1: Deterrence Penalty----

t1_det <- run_save_sensitivity(
  run_deterrence_sensitivity, plot_deterrence_sensitivity, "deterrence_sensitivity")

# 11. Tier 1: Conversion Probability (beta)----

t1_beta <- run_save_sensitivity(
  run_beta_sensitivity, plot_beta_sensitivity, "beta_sensitivity")

# 12. Tier 1: NC Switching Costs----

t1_switch <- run_save_sensitivity(
  run_switching_cost_sensitivity, plot_switching_cost_sensitivity,
  "switching_cost_sensitivity")

# 13. Tier 1: Best-Case Persecution----

t1_bc <- run_save_sensitivity(
  run_best_case_persecution, plot_best_case_persecution,
  "best_case_persecution")

# 14. Tier 1: Combined Panel----

ggsave("tier1_panel.png",
       plot_tier1_panel(t1_sol$results, t1_det$results,
                        t1_beta$results, t1_switch$results),
       width = 14, height = 10, dpi = 300)


# 15. Tier 2: Population Size----

t2_pop <- run_save_sensitivity_by_dist(
  run_population_sensitivity, plot_population_sensitivity,
  "population_sensitivity")

# 16. Tier 2: Network Mean Degree----

t2_net <- run_save_sensitivity_by_dist(
  run_network_degree_sensitivity, plot_network_degree_sensitivity,
  "network_degree_sensitivity")

# 17. Tier 2: Evangelism Intensity----

t2_evang <- run_save_sensitivity(
  run_evangelism_sensitivity, plot_evangelism_sensitivity,
  "evangelism_sensitivity")

# 18. Tier 2: Regulation Intensity----

t2_reg <- run_save_sensitivity(
  run_regulation_intensity_sensitivity, plot_regulation_intensity_sensitivity,
  "regulation_intensity_sensitivity")

# 19. Tier 2: Persecution Trigger Threshold----

t2_thresh <- run_save_sensitivity(
  run_persecution_threshold_sensitivity, plot_persecution_threshold_sensitivity,
  "persecution_threshold_sensitivity")

# 20. Tier 2: Persecution Impact (Christian)----

t2_pimp <- run_save_sensitivity(
  run_persecution_impact_chr_sensitivity, plot_persecution_impact_chr_sensitivity,
  "persecution_impact_chr_sensitivity")

# 21. Tier 2: Persecution Impact (NC)----

t2_pnc <- run_save_sensitivity(
  run_persecution_impact_nc_sensitivity, plot_persecution_impact_nc_sensitivity,
  "persecution_impact_nc_sensitivity")


# 22. Tier 3: R Decay Rate----

t3_decay <- run_save_sensitivity(
  run_R_decay_sensitivity, plot_R_decay_sensitivity, "R_decay_sensitivity")

# 23. Tier 3: Network Homophily----

t3_homo <- run_save_sensitivity(
  run_homophily_sensitivity, plot_homophily_sensitivity, "homophily_sensitivity")

# 24. Tier 3: R Drift Rate----

t3_drift <- run_save_sensitivity(
  run_R_drift_sensitivity, plot_R_drift_sensitivity, "R_drift_sensitivity")

# 25. Tier 3: Cross-Religion Conversion----

t3_cross <- run_save_sensitivity(
  run_cross_convert_sensitivity, plot_cross_convert_sensitivity,
  "cross_convert_sensitivity")

# 26. Tier 3: Initial Christian Share----

t3_init <- run_save_sensitivity(
  run_initial_share_sensitivity, plot_initial_share_sensitivity,
  "initial_share_sensitivity")


# 27. Mega-Test----

t_mega <- run_save_sensitivity_by_dist(
  run_mega_test, plot_mega_test, "mega_test")


# Print Summaries----
# Console output of key tables for quick review after the batch finishes.

cat("\n=== Overview ===\n")
print(tbl_overview)

cat("\n=== Denomination Shares (Final) ===\n")
print(tbl_denom[, 1:7])

cat("\n=== R Composition (Final) ===\n")
print(tbl_rcomp)

cat("\n=== Secular Sensitivity ===\n")
print(tbl_secular)

cat("\n=== Tier 1: Solidarity Boost ===\n")
print(t1_sol$table)

cat("\n=== Tier 1: Deterrence Penalty ===\n")
print(t1_det$table)

cat("\n=== Tier 1: Beta ===\n")
print(t1_beta$table)

cat("\n=== Tier 1: NC Switching Costs ===\n")
print(t1_switch$table)

cat("\n=== Tier 1: Best-Case Persecution ===\n")
print(t1_bc$table)

cat("\n=== Tier 2: Evangelism Intensity ===\n")
print(t2_evang$table)

cat("\n=== Tier 2: Regulation Intensity ===\n")
print(t2_reg$table)

cat("\n=== Mega-Test ===\n")
print(t_mega$table)


# File Manifest----
# Lists every output file produced by this script for easy reference.

cat("\n=== Output Files ===\n")
cat("  scenario_results.rds                          - full 20-cell results\n")
cat("  scenario_comparison.png                       - faceted plot\n")
cat("  convert_share.png                             - convert vs born-Christian\n")
cat("  tbl_overview.csv                              - 20-row summary\n")
cat("  tbl_denominations.csv                         - per-denomination breakdown\n")
cat("  tbl_nc_groups.csv                             - per-NC group final %\n")
cat("  tbl_r_composition.csv                         - High/Mid/Low R\n")
cat("  tbl_trajectory.csv                            - decade intervals\n")
cat("  tbl_timeseries.csv                            - full time series\n")
cat("  secular_sensitivity_results.rds / .png / .csv - secular cohort\n")
cat("  --- Tier 1 ---\n")
cat("  solidarity_sensitivity_results.rds / .png / .csv\n")
cat("  deterrence_sensitivity_results.rds / .png / .csv\n")
cat("  beta_sensitivity_results.rds / .png / .csv\n")
cat("  switching_cost_sensitivity_results.rds / .png / .csv\n")
cat("  best_case_persecution_results.rds / .png / .csv\n")
cat("  tier1_panel.png\n")
cat("  --- Tier 2 ---\n")
cat("  population_sensitivity_results.rds / .png / .csv\n")
cat("  network_degree_sensitivity_results.rds / .png / .csv\n")
cat("  evangelism_sensitivity_results.rds / .png / .csv\n")
cat("  regulation_intensity_sensitivity_results.rds / .png / .csv\n")
cat("  persecution_threshold_sensitivity_results.rds / .png / .csv\n")
cat("  persecution_impact_chr_sensitivity_results.rds / .png / .csv\n")
cat("  persecution_impact_nc_sensitivity_results.rds / .png / .csv\n")
cat("  --- Tier 3 ---\n")
cat("  R_decay_sensitivity_results.rds / .png / .csv\n")
cat("  homophily_sensitivity_results.rds / .png / .csv\n")
cat("  R_drift_sensitivity_results.rds / .png / .csv\n")
cat("  cross_convert_sensitivity_results.rds / .png / .csv\n")
cat("  initial_share_sensitivity_results.rds / .png / .csv\n")
cat("  --- Mega-Test ---\n")
cat("  mega_test_results.rds / .png / .csv\n")
cat("\nDone!\n")