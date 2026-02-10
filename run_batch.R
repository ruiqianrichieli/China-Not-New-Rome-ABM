# ----
# Model 1: Free Religious Market ABM - Batch Runner
# 5 Scenarios × 4 R Distributions = 20 runs
# All with network ON
# ----
# Usage: Rscript run_batch.R
# Or: source("run_batch.R")

library(dplyr)
library(tidyr)
library(ggplot2)

source("model_functions.R")
source("utils.R")

# ----
# Labels
# ----

scenario_labels <- c(
  "1: Christians + Nones Only (Free Market)",
  "2: Christians + Passive NCs (Free Market)",
  "3: Christians + Active NCs (Free Market)",
  "4: Christians + Passive NCs (Regulation)",
  "5: Christians + Active NCs (Regulation)"
)

dist_labels <- c(
  "normal" = "Normal",
  "bimodal" = "Bimodal",
  "right_skewed" = "Right-skewed",
  "left_skewed" = "Left-skewed"
)

# ----
# Run a Scenario
# ----

run_scenario <- function(scenario = 1, R_dist = "normal", n_reps = 10,
                         n_cores = NULL, ...) {
  params <- get_scenario_params(scenario, R_dist)
  extra <- list(...)
  for (nm in names(extra)) params[[nm]] <- extra[[nm]]
  params$n_replications <- n_reps
  
  cat("Scenario", scenario, "| R:", R_dist,
      "| Reps:", n_reps, "| NC:", params$n_nonchristian, "\n")
  
  t0 <- Sys.time()
  result <- run_replications(params, n_cores = n_cores)
  elapsed <- round(difftime(Sys.time(), t0, units = "mins"), 1)
  cat("  Done in", elapsed, "min\n\n")
  result
}

# ----
# Run All: 5 Scenarios × 4 Distributions
# ----

run_all_scenarios <- function(n_reps = 10, n_cores = NULL) {
  dists <- c("normal", "bimodal", "right_skewed", "left_skewed")
  results <- list()
  
  for (d in dists) {
    for (s in 1:5) {
      key <- paste0("s", s, "_", d)
      results[[key]] <- run_scenario(s, R_dist = d, n_reps = n_reps,
                                     n_cores = n_cores)
    }
  }
  results
}

# ----
# Comparison Plot: facet by R distribution
# ----

plot_scenario_comparison <- function(results_list) {
  dists <- c("normal", "bimodal", "right_skewed", "left_skewed")
  rows <- list()
  
  for (d in dists) {
    for (s in 1:5) {
      key <- paste0("s", s, "_", d)
      if (!is.null(results_list[[key]])) {
        rows[[length(rows) + 1]] <- results_list[[key]]$summary |>
          mutate(scenario = scenario_labels[s],
                 R_dist = dist_labels[d])
      }
    }
  }
  
  combined <- bind_rows(rows)
  combined$R_dist <- factor(combined$R_dist,
                            levels = c("Normal", "Bimodal", "Right-skewed", "Left-skewed"))
  
  ggplot(combined, aes(time, christian_pct_mean * 100, color = scenario)) +
    geom_ribbon(aes(ymin = christian_pct_lo * 100, ymax = christian_pct_hi * 100,
                    fill = scenario), alpha = 0.15, color = NA) +
    geom_line(linewidth = 1) +
    facet_wrap(~ R_dist, nrow = 2) +
    scale_y_continuous(limits = c(0, 70), breaks = seq(0, 70, 5)) +
    labs(title = "Christian % Across Scenarios x R Distributions",
         subtitle = "Shaded: 10th-90th percentile | Network ON | 5 Scenarios",
         x = "Year", y = "Christian %", color = NULL, fill = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(),
          strip.text = element_text(face = "bold"))
}

# ----
# Secular Sensitivity Analysis
# ----
# Varies secular_cohort_factor under Scenario 4 (regulated)
# + right-skewed R. Tests whether the demand ceiling is
# driven by secularization or regulation alone.

run_secular_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                    factors = c(1.0, 0.8, 0.6, 0.4, 0.2)) {
  results <- list()
  
  for (sf in factors) {
    label <- paste0("sf_", sf)
    cat("Secular factor:", sf, "| Reps:", n_reps, "\n")
    
    params <- get_scenario_params(4, "right_skewed")
    params$secular_cohort_factor <- sf
    params$n_replications <- n_reps
    
    result <- run_replications(params, n_cores = n_cores)
    result$secular_factor <- sf
    results[[label]] <- result
    cat("  Done.\n\n")
  }
  
  results
}

plot_secular_sensitivity <- function(results) {
  combined <- bind_rows(lapply(results, function(r) {
    r$summary |> mutate(secular_factor = r$secular_factor)
  }))
  
  factor_labels <- c(
    "1"   = "No secular decline",
    "0.8" = "20% transmission loss",
    "0.6" = "40% transmission loss",
    "0.4" = "60% transmission loss",
    "0.2" = "80% transmission loss"
  )
  
  combined$label <- factor(
    factor_labels[as.character(combined$secular_factor)],
    levels = rev(factor_labels)
  )
  
  ggplot(combined, aes(time, christian_pct_mean * 100,
                       color = label, fill = label)) +
    geom_ribbon(aes(ymin = christian_pct_lo * 100,
                    ymax = christian_pct_hi * 100),
                alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.9) +
    geom_vline(xintercept = 2012, linetype = "dashed",
               color = "gray50", linewidth = 0.4) +
    annotate("text", x = 2013, y = 1, label = "Secular cohort\nyear (2012)",
             hjust = 0, size = 3, color = "gray40") +
    scale_color_manual(
      values = c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b")
    ) +
    scale_fill_manual(
      values = c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b")
    ) +
    labs(
      title = "Christian Growth Under Regulation: Secular Cohort Sensitivity",
      subtitle = paste0("Right-skewed R + Scenario 4 (regulated, passive NC) | ",
                        "Shaded: 10th\u201390th percentile"),
      x = "Year", y = "Christian %",
      color = NULL, fill = NULL
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      plot.subtitle = element_text(size = 10, color = "gray40")
    )
}

summarize_secular_sensitivity <- function(results) {
  bind_rows(lapply(results, function(r) {
    s <- r$summary
    peak_row <- s[which.max(s$christian_pct_mean), ]
    final_row <- tail(s, 1)
    at_2020 <- s[which.min(abs(s$time - 2020)), ]
    at_2025 <- s[which.min(abs(s$time - 2025)), ]
    
    data.frame(
      secular_factor = r$secular_factor,
      peak_pct = round(peak_row$christian_pct_mean * 100, 1),
      peak_year = round(peak_row$time),
      pct_2020 = round(at_2020$christian_pct_mean * 100, 1),
      pct_2025 = round(at_2025$christian_pct_mean * 100, 1),
      final_pct = round(final_row$christian_pct_mean * 100, 1)
    )
  }))
}

# ----
# Main
# ----

if (interactive()) {
  n_det <- max(1L, parallel::detectCores() - 1L)
  cat("Model 1 Batch Runner\n")
  cat("====================\n")
  cat("5 Scenarios x 4 R Distributions = 20 runs\n")
  cat("All with network ON\n")
  cat("Detected cores:", n_det, "\n\n")
  cat("  run_scenario(2, 'normal', 10)       # single cell\n")
  cat("  run_all_scenarios(10)               # all 20 cells\n")
  cat("  plot_scenario_comparison(results)   # faceted plot\n\n")
  cat("  res <- run_secular_sensitivity(30)  # sensitivity\n")
  cat("  plot_secular_sensitivity(res)\n")
  cat("  summarize_secular_sensitivity(res)\n\n")
} else {
  cat("Running 5x4 comparison...\n\n")
  results <- run_all_scenarios(n_reps = 5)
  saveRDS(results, "scenario_results.rds")
  cat("\nSaved: scenario_results.rds\n")
  
  p <- plot_scenario_comparison(results)
  ggsave("scenario_comparison.png", p, width = 14, height = 8, dpi = 150)
  cat("Saved: scenario_comparison.png\n")
  
  cat("\n=== Final Christian % ===\n")
  for (nm in names(results)) {
    final <- tail(results[[nm]]$summary, 1)
    cat(nm, ": ", round(final$christian_pct_mean * 100, 2),
        "% (SD: ", round(final$christian_pct_sd * 100, 2), "%)\n", sep = "")
  }
  
  cat("\nRunning secular sensitivity (5 levels x 5 reps)...\n\n")
  sec_results <- run_secular_sensitivity(n_reps = 5)
  saveRDS(sec_results, "secular_sensitivity_results.rds")
  cat("Saved: secular_sensitivity_results.rds\n")
  
  p2 <- plot_secular_sensitivity(sec_results)
  ggsave("secular_sensitivity.png", p2, width = 10, height = 6, dpi = 300)
  cat("Saved: secular_sensitivity.png\n")
  
  cat("\n=== Secular Sensitivity Summary ===\n")
  print(summarize_secular_sensitivity(sec_results))
}