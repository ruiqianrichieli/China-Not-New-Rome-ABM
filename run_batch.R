# Model 1: Free Religious Market ABM - Batch Runner
# 5 Scenarios × 4 R Distributions = 20 runs, all with network ON
# Usage: Rscript run_batch.R  /  source("run_batch.R")

library(dplyr)
library(tidyr)
library(ggplot2)

source("model_functions.R")
source("utils.R")

# Labels----
# Human-readable names for the 5 scenarios and 4 R distributions.
# Used in plot legends and table outputs throughout.

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

all_dists <- c("normal", "bimodal", "right_skewed", "left_skewed")

# Run a Scenario----
# Runs one cell of the 5x4 design: picks scenario params, overrides
# any extras passed via ..., then fires off n_reps replications.

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

# Run All: 5 Scenarios × 4 Distributions----
# Loops through the full 20-cell design and stores results in a named list.

run_all_scenarios <- function(n_reps = 10, n_cores = NULL) {
  results <- list()
  for (d in all_dists) {
    for (s in 1:5) {
      key <- paste0("s", s, "_", d)
      results[[key]] <- run_scenario(s, R_dist = d, n_reps = n_reps,
                                     n_cores = n_cores)
    }
  }
  results
}

# Comparison Plot----
# Faceted line plot: Christian % over time, all 5 scenarios overlaid,
# one panel per R distribution. Shaded ribbon = 10th-90th percentile.

plot_scenario_comparison <- function(results_list) {
  rows <- list()
  for (d in all_dists) {
    for (s in 1:5) {
      key <- paste0("s", s, "_", d)
      if (!is.null(results_list[[key]])) {
        rows[[length(rows) + 1]] <- results_list[[key]]$summary |>
          mutate(scenario = scenario_labels[s], R_dist = dist_labels[d])
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

# Secular Sensitivity----

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
  
  fl <- c("1" = "No secular decline", "0.8" = "20% transmission loss",
          "0.6" = "40% transmission loss", "0.4" = "60% transmission loss",
          "0.2" = "80% transmission loss")
  combined$label <- factor(fl[as.character(combined$secular_factor)],
                           levels = rev(fl))
  
  ggplot(combined, aes(time, christian_pct_mean * 100,
                       color = label, fill = label)) +
    geom_ribbon(aes(ymin = christian_pct_lo * 100, ymax = christian_pct_hi * 100),
                alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.9) +
    geom_vline(xintercept = 2012, linetype = "dashed",
               color = "gray50", linewidth = 0.4) +
    annotate("text", x = 2013, y = 1, label = "Secular cohort\nyear (2012)",
             hjust = 0, size = 3, color = "gray40") +
    scale_color_manual(values = c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b")) +
    scale_fill_manual(values = c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b")) +
    labs(title = "Christian Growth Under Regulation: Secular Cohort Sensitivity",
         subtitle = "Right-skewed R + Scenario 4 (regulated, passive NC) | Shaded: 10th\u201390th percentile",
         x = "Year", y = "Christian %", color = NULL, fill = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(),
          plot.subtitle = element_text(size = 10, color = "gray40"))
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
      final_pct = round(final_row$christian_pct_mean * 100, 1))
  }))
}

# Generic Sensitivity Runner (single R dist)----
# Sweeps one parameter across a set of values under a fixed scenario
# and R distribution. Used by all Tier 1 and most Tier 2/3 tests.

run_sensitivity <- function(param_name, values, value_labels = NULL,
                            n_reps = 30, n_cores = NULL,
                            scenario = 4, R_dist = "right_skewed",
                            transform_fn = NULL) {
  results <- list()
  if (is.null(value_labels)) value_labels <- as.character(values)
  for (i in seq_along(values)) {
    v <- values[i]
    label <- value_labels[i]
    cat(param_name, "=", label, "| Reps:", n_reps, "\n")
    params <- get_scenario_params(scenario, R_dist)
    params$n_replications <- n_reps
    if (!is.null(transform_fn)) params <- transform_fn(params, v)
    else params[[param_name]] <- v
    result <- run_replications(params, n_cores = n_cores)
    result$param_value <- v
    result$param_label <- label
    results[[paste0("v_", i)]] <- result
    cat("  Done.\n\n")
  }
  results
}

# Generic Sensitivity Runner (multiple R dists)----
# Same as above but crosses the parameter sweep with all 4 R distributions.
# Used for population size, network degree, and the mega-test.

run_sensitivity_by_dist <- function(param_name, values, value_labels = NULL,
                                    n_reps = 30, n_cores = NULL,
                                    scenario = 4, dists = all_dists,
                                    transform_fn = NULL) {
  results <- list()
  if (is.null(value_labels)) value_labels <- as.character(values)
  for (d in dists) {
    for (i in seq_along(values)) {
      v <- values[i]
      label <- value_labels[i]
      cat(param_name, "=", label, "| R:", d, "| Reps:", n_reps, "\n")
      params <- get_scenario_params(scenario, d)
      params$n_replications <- n_reps
      if (!is.null(transform_fn)) params <- transform_fn(params, v)
      else params[[param_name]] <- v
      result <- run_replications(params, n_cores = n_cores)
      result$param_value <- v
      result$param_label <- label
      result$R_dist <- d
      results[[paste0(d, "_v", i)]] <- result
      cat("  Done.\n\n")
    }
  }
  results
}

# Generic Sensitivity Plot (single dist)----
# Standard line plot for single-distribution sensitivity tests.
# One line per parameter value, with 10th-90th percentile ribbons.

plot_sensitivity <- function(results, title, subtitle_extra = NULL,
                             palette = NULL) {
  combined <- bind_rows(lapply(results, function(r) {
    r$summary |> mutate(param_label = r$param_label)
  }))
  lvls <- unique(sapply(results, function(r) r$param_label))
  combined$param_label <- factor(combined$param_label, levels = lvls)
  n_lvls <- length(lvls)
  if (is.null(palette)) {
    palette <- if (n_lvls <= 6) {
      c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b", "#8e44ad")[1:n_lvls]
    } else colorRampPalette(c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b"))(n_lvls)
  }
  sub <- "Right-skewed R + Scenario 4 (regulated, passive NC) | Shaded: 10th\u201390th percentile"
  if (!is.null(subtitle_extra)) sub <- paste0(sub, " | ", subtitle_extra)
  
  ggplot(combined, aes(time, christian_pct_mean * 100,
                       color = param_label, fill = param_label)) +
    geom_ribbon(aes(ymin = christian_pct_lo * 100, ymax = christian_pct_hi * 100),
                alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.9) +
    geom_vline(xintercept = 2012, linetype = "dashed", color = "gray50", linewidth = 0.4) +
    scale_color_manual(values = palette) +
    scale_fill_manual(values = palette) +
    labs(title = title, subtitle = sub,
         x = "Year", y = "Christian %", color = NULL, fill = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(),
          plot.subtitle = element_text(size = 10, color = "gray40"))
}

# Generic Sensitivity Plot (multi-dist, faceted)----
# Faceted version for multi-distribution tests: one panel per R dist.

plot_sensitivity_by_dist <- function(results, title, palette = NULL) {
  combined <- bind_rows(lapply(results, function(r) {
    r$summary |> mutate(param_label = r$param_label, R_dist = r$R_dist)
  }))
  lvls <- unique(sapply(results, function(r) r$param_label))
  combined$param_label <- factor(combined$param_label, levels = lvls)
  combined$R_dist <- factor(dist_labels[combined$R_dist],
                            levels = c("Normal", "Bimodal", "Right-skewed", "Left-skewed"))
  n_lvls <- length(lvls)
  if (is.null(palette)) {
    palette <- if (n_lvls <= 6) {
      c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b", "#8e44ad")[1:n_lvls]
    } else colorRampPalette(c("#2c3e50", "#2980b9", "#27ae60", "#e67e22", "#c0392b"))(n_lvls)
  }
  
  ggplot(combined, aes(time, christian_pct_mean * 100,
                       color = param_label, fill = param_label)) +
    geom_ribbon(aes(ymin = christian_pct_lo * 100, ymax = christian_pct_hi * 100),
                alpha = 0.1, color = NA) +
    geom_line(linewidth = 0.8) +
    facet_wrap(~ R_dist, nrow = 2) +
    scale_color_manual(values = palette) +
    scale_fill_manual(values = palette) +
    labs(title = title,
         subtitle = "Scenario 4 (regulated, passive NC) | Shaded: 10th\u201390th percentile",
         x = "Year", y = "Christian %", color = NULL, fill = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(),
          strip.text = element_text(face = "bold"),
          plot.subtitle = element_text(size = 10, color = "gray40"))
}

# Generic Sensitivity Summary----
# Extracts peak Christian %, peak year, final %, and final mean R
# from each sensitivity run. Returns a tidy data.frame for CSV export.

summarize_sensitivity <- function(results) {
  bind_rows(lapply(results, function(r) {
    s <- r$summary
    peak_row <- s[which.max(s$christian_pct_mean), ]
    final_row <- tail(s, 1)
    row <- data.frame(
      param_label = r$param_label,
      param_value = r$param_value,
      peak_pct = round(peak_row$christian_pct_mean * 100, 1),
      peak_year = round(peak_row$time),
      final_pct = round(final_row$christian_pct_mean * 100, 1),
      final_R_mean = round(final_row$christian_R_mean, 3))
    if (!is.null(r$R_dist)) row$R_dist <- r$R_dist
    row
  }))
}

# Panel Plot Helper----
# Arranges multiple ggplots into a 2x2 panel using patchwork or gridExtra.

make_panel <- function(plot_list, title) {
  plot_list <- lapply(plot_list, function(p) {
    p + theme(legend.text = element_text(size = 7),
              plot.title = element_text(size = 11))
  })
  if (requireNamespace("patchwork", quietly = TRUE)) {
    library(patchwork)
    wrap_plots(plot_list, ncol = 2) +
      plot_annotation(title = title,
                      theme = theme(plot.title = element_text(size = 14, face = "bold")))
  } else if (requireNamespace("gridExtra", quietly = TRUE)) {
    gridExtra::grid.arrange(grobs = plot_list, ncol = 2,
                            top = grid::textGrob(title, gp = grid::gpar(fontsize = 14, fontface = "bold")))
  } else {
    message("Install patchwork or gridExtra for combined panels.")
    plot_list[[1]]
  }
}

# Tier 1 Test 1: Solidarity Boost----

run_solidarity_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                       values = c(0, 0.25, 0.5, 1.0, 1.5, 2.0)) {
  labels <- paste0("Solidarity = ", values)
  labels[values == 0.5] <- paste0(labels[values == 0.5], " (baseline)")
  run_sensitivity("solidarity_high_R", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_solidarity_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Solidarity Boost Sensitivity: Christian Growth Under Regulation")
}

# Tier 1 Test 2: Deterrence Penalty----

run_deterrence_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                       values = c(0, 0.25, 0.5, 0.75, 1.0, 1.5)) {
  labels <- paste0("Deterrence = ", values)
  labels[values == 0.5] <- paste0(labels[values == 0.5], " (baseline)")
  run_sensitivity("deterrence_low_R", -values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_deterrence_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Deterrence Penalty Sensitivity: Christian Growth Under Regulation")
}

# Tier 1 Test 3: Conversion Probability (beta)----

run_beta_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                 values = c(0.1, 0.2, 0.3, 0.5, 0.7, 0.9)) {
  labels <- paste0("\u03b2 = ", values)
  labels[values == 0.3] <- paste0(labels[values == 0.3], " (baseline)")
  run_sensitivity("base_convert_prob", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_beta_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Conversion Probability Sensitivity: Christian Growth Under Regulation")
}

# Tier 1 Test 4: NC Switching Costs----

run_switching_cost_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                           factors = c(0, 0.5, 1.0, 1.5, 2.0)) {
  labels <- paste0("Factor = ", factors, "\u00d7")
  labels[factors == 1.0] <- paste0(labels[factors == 1.0], " (baseline)")
  baseline_costs <- get_nc_defaults()$switching_cost
  tf <- function(params, fv) { params$nc_switching_cost <- baseline_costs * fv; params }
  run_sensitivity("nc_switching_cost_factor", factors, labels,
                  n_reps = n_reps, n_cores = n_cores, transform_fn = tf)
}

plot_switching_cost_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "NC Switching Cost Sensitivity: Christian Growth Under Regulation")
}

# Tier 1: Best-Case Persecution----

run_best_case_persecution <- function(n_reps = 30, n_cores = NULL) {
  cat("Baseline: solidarity=0.5, deterrence=0.5\n")
  p_bl <- get_scenario_params(4, "right_skewed")
  p_bl$n_replications <- n_reps
  bl <- run_replications(p_bl, n_cores = n_cores)
  bl$param_label <- "Baseline (sol=0.5, det=0.5)"
  bl$param_value <- NA
  cat("  Done.\n\n")
  
  cat("Best-case: solidarity=2.0, deterrence=0\n")
  p_bc <- get_scenario_params(4, "right_skewed")
  p_bc$n_replications <- n_reps
  p_bc$solidarity_high_R <- 2.0
  p_bc$deterrence_low_R <- 0
  bc <- run_replications(p_bc, n_cores = n_cores)
  bc$param_label <- "Best case (sol=2.0, det=0)"
  bc$param_value <- NA
  cat("  Done.\n\n")
  
  list(baseline = bl, best_case = bc)
}

plot_best_case_persecution <- function(results) {
  plot_sensitivity(results,
                   "Best-Case Persecution: Max Solidarity + Zero Deterrence",
                   palette = c("#2980b9", "#c0392b"))
}

# Tier 1: Combined 2x2 Panel----

plot_tier1_panel <- function(sol_res, det_res, beta_res, switch_res) {
  make_panel(list(
    plot_solidarity_sensitivity(sol_res) + labs(title = "Solidarity Boost"),
    plot_deterrence_sensitivity(det_res) + labs(title = "Deterrence Penalty"),
    plot_beta_sensitivity(beta_res) + labs(title = "Conversion Probability (\u03b2)"),
    plot_switching_cost_sensitivity(switch_res) + labs(title = "NC Switching Costs")
  ), "Tier 1 Parameter Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 5: Population Size (all 4 R dists)----

run_population_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                       values = c(5000L, 10000L, 20000L)) {
  labels <- paste0("N = ", trimws(format(values, big.mark = ",")))
  labels[values == 5000] <- paste0(labels[values == 5000], " (baseline)")
  tf <- function(params, v) { params$n_agents <- as.integer(v); params }
  run_sensitivity_by_dist("n_agents", values, labels,
                          n_reps = n_reps, n_cores = n_cores, transform_fn = tf)
}

plot_population_sensitivity <- function(results) {
  plot_sensitivity_by_dist(results,
                           "Population Size Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 6: Network Mean Degree (all 4 R dists)----

run_network_degree_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                           values = c(5L, 10L, 15L, 20L, 25L, 30L)) {
  labels <- paste0("k = ", values)
  labels[values == 15] <- paste0(labels[values == 15], " (baseline)")
  tf <- function(params, v) { params$network_ties <- as.integer(v); params }
  run_sensitivity_by_dist("network_ties", values, labels,
                          n_reps = n_reps, n_cores = n_cores, transform_fn = tf)
}

plot_network_degree_sensitivity <- function(results) {
  plot_sensitivity_by_dist(results,
                           "Network Degree Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 7: Evangelism Intensity Multiplier----

run_evangelism_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                       factors = c(0.5, 1.0, 1.5, 2.0, 3.0)) {
  labels <- paste0(factors, "\u00d7")
  labels[factors == 1.0] <- paste0(labels[factors == 1.0], " (baseline)")
  baseline_evang <- get_denomination_defaults()$evangelism
  tf <- function(params, fv) { params$denom_evangelism <- baseline_evang * fv; params }
  run_sensitivity("evangelism_multiplier", factors, labels,
                  n_reps = n_reps, n_cores = n_cores, transform_fn = tf)
}

plot_evangelism_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Evangelism Intensity Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 8a: Regulation Intensity----

run_regulation_intensity_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                                 values = c(0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0)) {
  labels <- paste0("Reg = ", values)
  labels[values == 0.5] <- paste0(labels[values == 0.5], " (baseline)")
  run_sensitivity("regulation_intensity", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_regulation_intensity_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Regulation Intensity Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 8b: Persecution Trigger Threshold----

run_persecution_threshold_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                                  values = c(0.02, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30)) {
  labels <- paste0("Threshold = ", values * 100, "%")
  labels[values == 0.05] <- paste0(labels[values == 0.05], " (baseline)")
  run_sensitivity("persecution_threshold", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_persecution_threshold_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Persecution Threshold Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 8c: Persecution Impact on Christians----

run_persecution_impact_chr_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                                   values = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)) {
  labels <- paste0("Impact = ", values)
  labels[values == 0.3] <- paste0(labels[values == 0.3], " (baseline)")
  run_sensitivity("persecution_impact_christian", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_persecution_impact_chr_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Persecution Impact (Christian) Sensitivity: Christian Growth Under Regulation")
}

# Tier 2 Test 8d: Persecution Impact on NC Groups----

run_persecution_impact_nc_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                                  values = c(0, 0.1, 0.3, 0.5)) {
  labels <- paste0("NC Impact = ", values)
  labels[values == 0.1] <- paste0(labels[values == 0.1], " (baseline)")
  run_sensitivity("persecution_impact_nc", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_persecution_impact_nc_sensitivity <- function(results) {
  plot_sensitivity(results,
                   "Persecution Impact (NC) Sensitivity: Christian Growth Under Regulation")
}

# Tier 3 Test 9: R Decay Rate----

run_R_decay_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                    values = c(0, 0.005, 0.01, 0.02, 0.03)) {
  labels <- paste0("\u03b4 = ", values)
  labels[values == 0.01] <- paste0(labels[values == 0.01], " (baseline)")
  run_sensitivity("R_decay_none", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_R_decay_sensitivity <- function(results) {
  plot_sensitivity(results, "R Decay Rate Sensitivity: Christian Growth Under Regulation")
}

# Tier 3 Test 10: Network Homophily----

run_homophily_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                      values = c(0.20, 0.35, 0.50, 0.70)) {
  labels <- paste0("Homophily = ", values * 100, "%")
  labels[values == 0.50] <- paste0(labels[values == 0.50], " (baseline)")
  run_sensitivity("network_christian_homophily", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_homophily_sensitivity <- function(results) {
  plot_sensitivity(results, "Network Homophily Sensitivity: Christian Growth Under Regulation")
}

# Tier 3 Test 11: R Drift Rate----

run_R_drift_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                    values = c(0, 0.015, 0.03, 0.06, 0.1)) {
  labels <- paste0("\u03b3 = ", values)
  labels[values == 0.03] <- paste0(labels[values == 0.03], " (baseline)")
  run_sensitivity("R_drift_rate", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_R_drift_sensitivity <- function(results) {
  plot_sensitivity(results, "R Drift Rate Sensitivity: Christian Growth Under Regulation")
}

# Tier 3 Test 12: Cross-Religion Conversion Probability----

run_cross_convert_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                          values = c(0.05, 0.10, 0.15, 0.25, 0.40)) {
  labels <- paste0("P(cross) = ", values)
  labels[values == 0.15] <- paste0(labels[values == 0.15], " (baseline)")
  run_sensitivity("cross_convert_prob", values, labels,
                  n_reps = n_reps, n_cores = n_cores)
}

plot_cross_convert_sensitivity <- function(results) {
  plot_sensitivity(results, "Cross-Religion Conversion Sensitivity: Christian Growth Under Regulation")
}

# Tier 3 Test 13: Initial Christian Share----

run_initial_share_sensitivity <- function(n_reps = 30, n_cores = NULL,
                                          total_pcts = c(0.0025, 0.005, 0.01, 0.02, 0.03)) {
  labels <- paste0(total_pcts * 100, "%")
  labels[total_pcts == 0.005] <- paste0(labels[total_pcts == 0.005], " (baseline)")
  tf <- function(params, v) { params$denom_initial_pct <- rep(v / 5, 5); params }
  run_sensitivity("initial_christian_pct", total_pcts, labels,
                  n_reps = n_reps, n_cores = n_cores, transform_fn = tf)
}

plot_initial_share_sensitivity <- function(results) {
  plot_sensitivity(results, "Initial Christian Share Sensitivity: Christian Growth Under Regulation")
}

# Mega-Test: All Parameters Maximally Favorable (all 4 R dists)----

apply_mega_params <- function(params) {
  params$solidarity_high_R <- 2.0
  params$deterrence_low_R <- 0
  params$persecution_impact_christian <- 0.1
  params$base_convert_prob <- 0.9
  params$nc_switching_cost <- rep(0, 5)
  params$denom_evangelism <- get_denomination_defaults()$evangelism * 3.0
  params$network_ties <- 30L
  params
}

run_mega_test <- function(n_reps = 30, n_cores = NULL,
                          dists = all_dists) {
  results <- list()
  for (d in dists) {
    cat("Mega-test baseline | R:", d, "\n")
    p_bl <- get_scenario_params(4, d)
    p_bl$n_replications <- n_reps
    bl <- run_replications(p_bl, n_cores = n_cores)
    bl$param_label <- "Baseline"
    bl$param_value <- NA_real_
    bl$R_dist <- d
    results[[paste0(d, "_bl")]] <- bl
    cat("  Done.\n\n")
    
    cat("Mega-test all max  | R:", d, "\n")
    p_mg <- apply_mega_params(get_scenario_params(4, d))
    p_mg$n_replications <- n_reps
    mg <- run_replications(p_mg, n_cores = n_cores)
    mg$param_label <- "Mega-test (all max)"
    mg$param_value <- NA_real_
    mg$R_dist <- d
    results[[paste0(d, "_mg")]] <- mg
    cat("  Done.\n\n")
  }
  results
}

plot_mega_test <- function(results) {
  plot_sensitivity_by_dist(results,
                           "Mega-Test: All Parameters Maximally Favorable to Christianity",
                           palette = c("#2980b9", "#c0392b"))
}
# Convert Share Plot----
# Shows what fraction of Christians entered via conversion (vs. born-in)
# over time. Addresses Reviewer 2's request to distinguish converts.

plot_convert_share <- function(results_list) {
  rows <- list()
  for (d in all_dists) {
    for (s in 1:5) {
      key <- paste0("s", s, "_", d)
      if (!is.null(results_list[[key]])) {
        rows[[length(rows) + 1]] <- results_list[[key]]$summary |>
          mutate(scenario = scenario_labels[s], R_dist = dist_labels[d])
      }
    }
  }
  
  combined <- bind_rows(rows)
  combined$R_dist <- factor(combined$R_dist,
                            levels = c("Normal", "Bimodal", "Right-skewed", "Left-skewed"))
  
  ggplot(combined, aes(time, christian_convert_pct_mean * 100, color = scenario)) +
    geom_line(linewidth = 0.9) +
    facet_wrap(~ R_dist, nrow = 2) +
    scale_y_continuous(limits = c(0, NA)) +
    labs(title = "Convert Share Among Christians Across Scenarios",
         subtitle = "% of Christians who entered via conversion (vs. born-Christian)",
         x = "Year", y = "Convert %", color = NULL) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom", panel.grid.minor = element_blank(),
          strip.text = element_text(face = "bold"))
}

# Main----
# When sourced interactively, prints a menu of available functions.
# When run via Rscript, does a quick 5-rep run + secular sensitivity.

if (interactive()) {
  n_det <- max(1L, parallel::detectCores() - 1L)
  cat("Model 1 Batch Runner\n")
  cat("====================\n")
  cat("Detected cores:", n_det, "\n\n")
  cat("  run_all_scenarios(10)\n")
  cat("  plot_scenario_comparison(results)\n\n")
  cat("  # Secular\n")
  cat("  run_secular_sensitivity(30)\n\n")
  cat("  # Tier 1\n")
  cat("  run_solidarity_sensitivity(30)\n")
  cat("  run_deterrence_sensitivity(30)\n")
  cat("  run_beta_sensitivity(30)\n")
  cat("  run_switching_cost_sensitivity(30)\n")
  cat("  run_best_case_persecution(30)\n\n")
  cat("  # Tier 2\n")
  cat("  run_population_sensitivity(30)\n")
  cat("  run_network_degree_sensitivity(30)\n")
  cat("  run_evangelism_sensitivity(30)\n")
  cat("  run_regulation_intensity_sensitivity(30)\n")
  cat("  run_persecution_threshold_sensitivity(30)\n")
  cat("  run_persecution_impact_chr_sensitivity(30)\n")
  cat("  run_persecution_impact_nc_sensitivity(30)\n\n")
  cat("  # Tier 3\n")
  cat("  run_R_decay_sensitivity(30)\n")
  cat("  run_homophily_sensitivity(30)\n")
  cat("  run_R_drift_sensitivity(30)\n")
  cat("  run_cross_convert_sensitivity(30)\n")
  cat("  run_initial_share_sensitivity(30)\n\n")
  cat("  # Mega-test\n")
  cat("  run_mega_test(30)\n\n")
} else {
  cat("Running 5x4 comparison...\n\n")
  results <- run_all_scenarios(n_reps = 5)
  saveRDS(results, "scenario_results.rds")
  cat("\nSaved: scenario_results.rds\n")
  
  p <- plot_scenario_comparison(results)
  ggsave("scenario_comparison.png", p, width = 14, height = 8, dpi = 150)
  
  cat("\nRunning secular sensitivity (5 levels x 5 reps)...\n\n")
  sec_results <- run_secular_sensitivity(n_reps = 5)
  saveRDS(sec_results, "secular_sensitivity_results.rds")
  
  cat("\n=== Secular Sensitivity Summary ===\n")
  print(summarize_secular_sensitivity(sec_results))
}