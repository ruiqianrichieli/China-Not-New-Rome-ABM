# ----
# Sensitivity Analysis: Secular Cohort Factor
# Right-skewed R + Regulation (Scenario 4)
# ----
# Tests how intergenerational secularization affects
# the demand ceiling under empirically relevant conditions.
#
# Usage: Rscript Sensitivity_test.R
# Or: source("Sensitivity_test.R")

source("run_batch.R")

# ----
# Main
# ----

if (interactive()) {
  cat("Secular Cohort Sensitivity Analysis\n")
  cat("====================================\n\n")
  cat("  res <- run_secular_sensitivity(n_reps = 30)\n")
  cat("  plot_secular_sensitivity(res)\n")
  cat("  summarize_secular_sensitivity(res)\n\n")
} else {
  cat("Running secular sensitivity (5 levels x 30 reps)...\n\n")
  results <- run_secular_sensitivity(n_reps = 30)

  saveRDS(results, "secular_sensitivity_results.rds")
  cat("Saved: secular_sensitivity_results.rds\n")

  p <- plot_secular_sensitivity(results)
  ggsave("secular_sensitivity.png", p, width = 10, height = 6, dpi = 300)
  cat("Saved: secular_sensitivity.png\n")

  cat("\n=== Summary ===\n")
  print(summarize_secular_sensitivity(results))
}
