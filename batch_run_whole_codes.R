# Run batch and extract results
# 20 runs: 5 scenarios × 4 R distributions


# Set working directory to script location (RStudio only; skip if running from terminal)
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



# Helpers


dists <- c("normal", "bimodal", "right_skewed", "left_skewed")
dist_labels <- c(normal = "Normal", bimodal = "Bimodal",
                 right_skewed = "Right-skewed", left_skewed = "Left-skewed")
sc_labels <- c(
  "1: Chr + Nones (Free)", "2: Chr + Passive NC (Free)",
  "3: Chr + Active NC (Free)", "4: Chr + Passive NC (Reg)",
  "5: Chr + Active NC (Reg)")
denom_names <- c("Evangelical", "Mainline", "Catholic", "Charismatic", "Other Christian")
denom_keys <- c("evangelical", "mainline", "catholic", "charismatic", "other_christian")


# Scenario summary function


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
        Persecution_Ever = ifelse(max(sm$persecution_pct) > 0, "Yes", "No"),
        stringsAsFactors = FALSE
      )
    }
  }
  do.call(rbind, rows)
}


# 1. Comparison plot


ggsave("scenario_comparison.png", plot_scenario_comparison(results),
       width = 14, height = 8, dpi = 150)


# 2. Overall summary table (20 rows)


tbl_overview <- summarize_scenarios(results)
write.csv(tbl_overview, "tbl_overview.csv", row.names = FALSE)


# 3. Denomination breakdown (final shares within Christianity)


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


# 4. NC group breakdown (final, scenarios 2-5 only)


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


# 5. R composition (High/Mid/Low % among Christians, final)


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


# 6. Growth trajectory (Christian % at key years)


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


# 7. Full time series (all scenarios, mean summary)


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


# 8. Secular sensitivity (right-skewed + regulation)


cat("\n=== Running Secular Sensitivity ===\n\n")

sec_results <- run_secular_sensitivity(n_reps = 30)
saveRDS(sec_results, "secular_sensitivity_results.rds")

ggsave("secular_sensitivity.png", plot_secular_sensitivity(sec_results),
       width = 10, height = 6, dpi = 300)

tbl_secular <- summarize_secular_sensitivity(sec_results)
write.csv(tbl_secular, "tbl_secular_sensitivity.csv", row.names = FALSE)


# Print


cat("\n=== Overview ===\n")
print(tbl_overview)

cat("\n=== Denomination Shares (Final) ===\n")
print(tbl_denom[, 1:7])

cat("\n=== R Composition (Final) ===\n")
print(tbl_rcomp)

cat("\n=== Secular Sensitivity ===\n")
print(tbl_secular)

cat("\nSaved:\n")
cat("  scenario_results.rds            - full results object\n")
cat("  scenario_comparison.png         - faceted plot\n")
cat("  tbl_overview.csv                - 20-row summary (peak, final, etc.)\n")
cat("  tbl_denominations.csv           - per-denomination pop%, market share, mean R\n")
cat("  tbl_nc_groups.csv               - per-NC group final %\n")
cat("  tbl_r_composition.csv           - High/Mid/Low R among Christians\n")
cat("  tbl_trajectory.csv              - Christian % at decade intervals\n")
cat("  tbl_timeseries.csv              - full time series (all scenarios)\n")
cat("  secular_sensitivity_results.rds - secular sensitivity results\n")
cat("  secular_sensitivity.png         - secular sensitivity plot\n")
cat("  tbl_secular_sensitivity.csv     - secular sensitivity summary\n")
cat("\nDone!\n")