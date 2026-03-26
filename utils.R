# ----
# Model 1: Free Religious Market ABM
# Utility / Plotting Functions
# ----

# ----
# Color Palettes
# ----

denom_colors <- function() {
  c("Evangelical" = "#c0392b", "Mainline" = "#2980b9", "Catholic" = "#8e44ad",
    "Charismatic" = "#d35400", "Other Christian" = "#27ae60")
}

nc_colors <- function(n = 5) {
  pal <- c("#1abc9c", "#f39c12", "#3498db", "#e74c3c", "#9b59b6")
  pal[1:min(n, 5)]
}

group_colors <- function(denom_names = NULL, nc_names = NULL) {
  cols <- denom_colors()
  if (!is.null(nc_names) && length(nc_names) > 0) {
    nc_pal <- nc_colors(length(nc_names))
    names(nc_pal) <- nc_names
    cols <- c(cols, nc_pal)
  }
  cols["None"] <- "gray60"
  cols
}

# ----
# Summarization
# ----

summarize_replications <- function(all_runs) {
  all_runs |>
    dplyr::group_by(time) |>
    dplyr::summarize(
      christian_pct_mean = mean(christian_pct, na.rm = TRUE),
      christian_pct_sd = sd(christian_pct, na.rm = TRUE),
      christian_pct_lo = quantile(christian_pct, 0.1, na.rm = TRUE),
      christian_pct_hi = quantile(christian_pct, 0.9, na.rm = TRUE),
      total_nc_pct_mean = mean(total_nc_pct, na.rm = TRUE),
      none_pct_mean = mean(none_pct, na.rm = TRUE),
      christian_R_mean = mean(christian_R_mean, na.rm = TRUE),
      persecution_pct = mean(persecution_active, na.rm = TRUE),
      .groups = "drop"
    )
}

# ----
# Population Shares (Christian / NC / None aggregate)
# ----

plot_population_shares <- function(results_df) {
  pd <- results_df |>
    dplyr::select(time, christian_pct, total_nc_pct, none_pct) |>
    tidyr::pivot_longer(-time, names_to = "group", values_to = "pct") |>
    dplyr::mutate(
      group = dplyr::case_when(
        group == "christian_pct" ~ "Christian",
        group == "total_nc_pct" ~ "Non-Christian",
        group == "none_pct" ~ "None"),
      group = factor(group, levels = c("Christian", "Non-Christian", "None")))

  ggplot2::ggplot(pd, ggplot2::aes(time, pct * 100, color = group)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(values = c(
      "Christian" = "#c0392b", "Non-Christian" = "#2980b9", "None" = "gray50")) +
    ggplot2::labs(title = "Population Shares", x = "Year", y = "%", color = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

# ----
# Denomination Population Shares
# ----

plot_denomination_shares <- function(results_df, denom_names) {
  keys <- gsub(" ", "_", tolower(denom_names))
  pct_cols <- paste0(keys, "_pct")
  avail <- intersect(pct_cols, names(results_df))
  if (length(avail) == 0) return(NULL)

  pd <- results_df |>
    dplyr::select(time, dplyr::all_of(avail)) |>
    tidyr::pivot_longer(-time, names_to = "denom", values_to = "pct")

  name_map <- setNames(denom_names, pct_cols)
  pd$denom <- name_map[pd$denom]

  cols <- denom_colors()

  ggplot2::ggplot(pd, ggplot2::aes(time, pct * 100, color = denom)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(values = cols) +
    ggplot2::labs(title = "Denomination Shares", x = "Year", y = "%", color = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

# ----
# Christian Market Share (within-Christianity proportions)
# ----

plot_christian_market_share <- function(results_df, denom_names) {
  keys <- gsub(" ", "_", tolower(denom_names))
  pct_cols <- paste0(keys, "_pct")
  avail <- intersect(pct_cols, names(results_df))
  if (length(avail) == 0) return(NULL)

  df <- results_df |> dplyr::select(time, dplyr::all_of(avail))
  total <- rowSums(df[, -1, drop = FALSE], na.rm = TRUE)
  total[total == 0] <- 1
  for (col in avail) df[[col]] <- df[[col]] / total

  pd <- df |>
    tidyr::pivot_longer(-time, names_to = "denom", values_to = "share")
  name_map <- setNames(denom_names, pct_cols)
  pd$denom <- name_map[pd$denom]

  ggplot2::ggplot(pd, ggplot2::aes(time, share * 100, fill = denom)) +
    ggplot2::geom_area(alpha = 0.8) +
    ggplot2::scale_fill_manual(values = denom_colors()) +
    ggplot2::labs(title = "Market Share Within Christianity", x = "Year", y = "%", fill = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

# ----
# Denomination Mean R Over Time
# ----

plot_denom_R_means <- function(results_df, denom_names) {
  keys <- gsub(" ", "_", tolower(denom_names))
  r_cols <- paste0(keys, "_R_mean")
  avail <- intersect(r_cols, names(results_df))
  if (length(avail) == 0) return(NULL)

  pd <- results_df |>
    dplyr::select(time, dplyr::all_of(avail)) |>
    tidyr::pivot_longer(-time, names_to = "denom", values_to = "R_mean")
  name_map <- setNames(denom_names, r_cols)
  pd$denom <- name_map[pd$denom]

  ggplot2::ggplot(pd, ggplot2::aes(time, R_mean, color = denom)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(values = denom_colors()) +
    ggplot2::labs(title = "Mean R by Denomination", x = "Year", y = "Mean R", color = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

# ----
# Christian R Composition (High/Mid/Low stacked area)
# ----

plot_christian_R_composition <- function(results_df) {
  pd <- results_df |>
    dplyr::select(time, christian_R_high_pct, christian_R_mid_pct, christian_R_low_pct) |>
    tidyr::pivot_longer(-time, names_to = "cat", values_to = "pct") |>
    dplyr::mutate(
      cat = dplyr::case_when(
        cat == "christian_R_high_pct" ~ "High R",
        cat == "christian_R_mid_pct" ~ "Mid R",
        cat == "christian_R_low_pct" ~ "Low R"),
      cat = factor(cat, levels = c("High R", "Mid R", "Low R")))

  ggplot2::ggplot(pd, ggplot2::aes(time, pct * 100, fill = cat)) +
    ggplot2::geom_area(alpha = 0.7) +
    ggplot2::scale_fill_manual(values = c("High R" = "#27ae60", "Mid R" = "#f39c12", "Low R" = "#e74c3c")) +
    ggplot2::labs(title = "Christian R Composition", x = "Year", y = "% of Christians", fill = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")
}

# ----
# NC Group Shares
# ----

plot_nc_shares <- function(results_df, nc_names_active, n_nc) {
  if (n_nc == 0) return(NULL)
  pct_cols <- paste0("nc_", 1:n_nc, "_pct")
  avail <- intersect(pct_cols, names(results_df))
  if (length(avail) == 0) return(NULL)

  pd <- results_df |>
    dplyr::select(time, dplyr::all_of(avail)) |>
    tidyr::pivot_longer(-time, names_to = "group", values_to = "pct")
  name_map <- setNames(nc_names_active[1:length(avail)], avail)
  pd$group <- name_map[pd$group]

  pal <- nc_colors(n_nc)
  names(pal) <- nc_names_active[1:n_nc]

  ggplot2::ggplot(pd, ggplot2::aes(time, pct * 100, color = group)) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::scale_color_manual(values = pal) +
    ggplot2::labs(title = "NC Group Population", x = "Year", y = "%", color = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom", panel.grid.minor = ggplot2::element_blank())
}

# ----
# R Distribution (final agents)
# ----

plot_R_distribution <- function(agents, params) {
  high_t <- safe_val(params$R_high_threshold, 1.0)
  low_t <- safe_val(params$R_low_threshold, 0.0)

  denom_names <- params$denom_names
  is_chr <- agents$identity %in% denom_names
  agents$group <- ifelse(is_chr, "Christian",
                         ifelse(agents$identity == "None", "None", "NC"))

  ggplot2::ggplot(agents, ggplot2::aes(R, fill = group)) +
    ggplot2::geom_histogram(bins = 40, alpha = 0.7, position = "identity") +
    ggplot2::geom_vline(xintercept = c(low_t, high_t), linetype = "dashed", color = "gray40") +
    ggplot2::scale_fill_manual(values = c("Christian" = "#c0392b", "NC" = "#2980b9", "None" = "gray70")) +
    ggplot2::labs(title = "R Distribution", x = "R", y = "Count", fill = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")
}

# ----
# Agent Scatter (R x Tenure)
# ----

plot_agent_scatter <- function(agents, params) {
  high_t <- safe_val(params$R_high_threshold, 1.0)
  low_t <- safe_val(params$R_low_threshold, 0.0)

  denom_names <- params$denom_names
  is_chr <- agents$identity %in% denom_names
  agents$group <- ifelse(is_chr, "Christian",
                         ifelse(agents$identity == "None", "None", "NC"))

  samp <- if (nrow(agents) > 3000) agents[sample(nrow(agents), 3000), ] else agents

  ggplot2::ggplot(samp, ggplot2::aes(R, tenure, color = group)) +
    ggplot2::geom_point(alpha = 0.5, size = 1.5) +
    ggplot2::geom_vline(xintercept = c(low_t, high_t), linetype = "dashed", color = "gray40") +
    ggplot2::scale_color_manual(values = c("Christian" = "#c0392b", "NC" = "#2980b9", "None" = "gray60")) +
    ggplot2::labs(x = "R", y = "Tenure", color = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")
}

# ----
# Replications Ribbon Plot
# ----

plot_replications <- function(summary_df, all_runs = NULL) {
  p <- ggplot2::ggplot(summary_df, ggplot2::aes(time)) +
    ggplot2::geom_ribbon(ggplot2::aes(
      ymin = christian_pct_lo * 100, ymax = christian_pct_hi * 100),
      fill = "#c0392b", alpha = 0.2) +
    ggplot2::geom_line(ggplot2::aes(y = christian_pct_mean * 100),
                       color = "#c0392b", linewidth = 1)

  if (!is.null(all_runs)) {
    p <- p + ggplot2::geom_line(
      data = all_runs,
      ggplot2::aes(time, christian_pct * 100, group = replication),
      alpha = 0.08, color = "#c0392b")
  }

  p + ggplot2::labs(title = "Christian % Across Replications",
                    subtitle = "Shaded: 10th-90th percentile", x = "Year", y = "Christian %") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
}

# ----
# Export
# ----

export_params <- function(params, filename) {
  df <- data.frame(
    parameter = names(params),
    value = sapply(params, function(x) {
      if (is.null(x)) "NULL"
      else if (length(x) > 1) paste(x, collapse = ", ")
      else as.character(x)
    }),
    stringsAsFactors = FALSE)
  write.csv(df, filename, row.names = FALSE)
}

# ----
# Scenario Presets
# ----

get_scenario_params <- function(scenario = 1, R_dist = "normal") {
  params <- get_default_params()

  # Network ON for all scenarios
  params$network_enabled <- TRUE

  # R distribution
  params$R_dist_type <- R_dist

  if (scenario == 1) {

    # Christians and Nones Only (Free Market)
    params$n_nonchristian <- 0L
  } else if (scenario == 2) {

    # Christians and Passive NCs (Free Market)
    params$n_nonchristian <- 4L
  } else if (scenario == 3) {

    # Christians and Active NCs (Free Market)
    params$n_nonchristian <- 4L
    params$nc_active[1:4] <- c(TRUE, TRUE, TRUE, TRUE)
    params$nc_evangelism[1:4] <- c(0.20, 0.10, 0.10, 0.10)
  } else if (scenario == 4) {

    # Christians + Passive NCs (Regulation)
    params$n_nonchristian <- 4L
    params$regulation_intensity <- 0.5
    params$persecution_threshold <- 0.05
    params$persecution_impact_christian <- 0.3
    params$persecution_impact_nc <- 0.1
    params$deterrence_low_R <- -0.5
    params$solidarity_high_R <- 0.5
  } else if (scenario == 5) {

    # Christians + Active NCs (Regulation)
    params$n_nonchristian <- 4L
    params$nc_active[1:4] <- c(TRUE, TRUE, TRUE, TRUE)
    params$nc_evangelism[1:4] <- c(0.20, 0.10, 0.10, 0.10)
    params$regulation_intensity <- 0.5
    params$persecution_threshold <- 0.05
    params$persecution_impact_christian <- 0.3
    params$persecution_impact_nc <- 0.1
    params$deterrence_low_R <- -0.5
    params$solidarity_high_R <- 0.5
  }
  params
}

# ----
# Spatial Map (NetLogo-style)
# ----

plot_spatial_map <- function(agents, params, title = "Agent Map",
                             detail = TRUE, show_R = FALSE) {
  if (is.null(agents) || nrow(agents) == 0 ||
      !("x" %in% names(agents)) || !("y" %in% names(agents))) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = .5, y = .5,
                               label = "No spatial data", size = 5, color = "gray50") +
             ggplot2::theme_void())
  }

  denom_names <- params$denom_names
  nc <- get_active_nc(params)

  if (detail) {

    # Detailed: each denomination / NC group gets own color
    agents$group <- agents$identity
    agents$group[agents$group == "None"] <- "None"

    dc <- denom_colors()
    nc_pal <- if (nc$n > 0) {
      p <- nc_colors(nc$n)
      names(p) <- nc$names[1:nc$n]
      p
    } else character(0)
    pal <- c(dc, nc_pal, "None" = "gray80")

    # Reorder: None in back, religious in front
    agents$is_none <- agents$identity == "None"
    agents <- agents[order(-agents$is_none), ]

    # Ensure factor levels for legend order
    lvls <- c(denom_names, if (nc$n > 0) nc$names[1:nc$n], "None")
    agents$group <- factor(agents$group, levels = lvls)
  } else {
    agents$group <- ifelse(
      agents$identity %in% denom_names, "Christian",
      ifelse(agents$identity == "None", "None", "NC"))
    pal <- c("Christian" = "#c0392b", "NC" = "#2980b9", "None" = "gray80")
    agents$is_none <- agents$identity == "None"
    agents <- agents[order(-agents$is_none), ]
    agents$group <- factor(agents$group, levels = c("Christian", "NC", "None"))
  }

  p <- ggplot2::ggplot(agents, ggplot2::aes(x, y, color = group))

  if (show_R) {
    p <- p +
      ggplot2::geom_point(ggplot2::aes(size = pmax(0.3, (R + 2) / 4)),
                          alpha = 0.7) +
      ggplot2::scale_size_identity() +
      ggplot2::guides(size = "none")
  } else {
    p <- p + ggplot2::geom_point(alpha = 0.7, size = 1.2)
  }

  p <- p +
    ggplot2::scale_color_manual(values = pal, drop = FALSE) +
    ggplot2::coord_fixed(xlim = c(0, 1), ylim = c(0, 1)) +
    ggplot2::labs(title = title, color = NULL) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = ggplot2::element_text(hjust = 0.5, size = 13),
      panel.background = ggplot2::element_rect(fill = "gray97", color = NA),
      legend.text = ggplot2::element_text(size = 9))

  p
}

# ----
# Network Graph Visualization
# ----

plot_network_graph <- function(agents, network, params, n_sample = 400,
                               title = "Network") {
  if (is.null(network) || is.null(agents)) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = .5, y = .5,
                               label = "Network not enabled", size = 5, color = "gray50") +
             ggplot2::theme_void())
  }

  if (!requireNamespace("igraph", quietly = TRUE)) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = .5, y = .5,
                               label = "Install igraph: install.packages('igraph')",
                               size = 4, color = "gray50") +
             ggplot2::theme_void())
  }

  n <- nrow(agents)
  denom_names <- params$denom_names

  # Sample agents
  samp_ids <- if (n > n_sample) sort(sample(1:n, n_sample)) else 1:n
  samp_set <- samp_ids

  # Build edge list for sampled subgraph
  edges <- data.frame(from = integer(0), to = integer(0))
  for (i in samp_set) {
    nbrs <- intersect(network[[i]], samp_set)
    if (length(nbrs) > 0) {
      edges <- rbind(edges, data.frame(from = i, to = nbrs))
    }
  }
  # Remove duplicates (keep i < j)
  if (nrow(edges) > 0) {
    edges <- edges[edges$from < edges$to, ]
    edges <- unique(edges)
  }

  # Remap IDs to 1:n_sample
  id_map <- setNames(seq_along(samp_set), samp_set)
  node_df <- data.frame(
    id = seq_along(samp_set),
    identity = agents$identity[samp_set],
    R = agents$R[samp_set],
    stringsAsFactors = FALSE
  )

  # Classify groups
  node_df$group <- ifelse(
    node_df$identity %in% denom_names, "Christian",
    ifelse(node_df$identity == "None", "None", node_df$identity))

  # Build igraph and compute layout
  if (nrow(edges) > 0) {
    edges$from <- id_map[as.character(edges$from)]
    edges$to <- id_map[as.character(edges$to)]
    g <- igraph::graph_from_data_frame(edges, directed = FALSE,
                                       vertices = node_df)
  } else {
    g <- igraph::make_empty_graph(n = nrow(node_df), directed = FALSE)
    igraph::V(g)$name <- as.character(node_df$id)
  }

  layout <- igraph::layout_with_fr(g, niter = 300)
  node_df$x <- layout[, 1]
  node_df$y <- layout[, 2]

  # Build edge segments for ggplot
  if (nrow(edges) > 0) {
    seg_df <- data.frame(
      x = node_df$x[edges$from], y = node_df$y[edges$from],
      xend = node_df$x[edges$to], yend = node_df$y[edges$to])
  } else {
    seg_df <- data.frame(x = numeric(0), y = numeric(0),
                         xend = numeric(0), yend = numeric(0))
  }

  # Color palette
  nc <- get_active_nc(params)
  all_groups <- unique(node_df$group)
  pal <- c("Christian" = "#c0392b", "None" = "gray70")
  if (nc$n > 0) {
    nc_pal <- nc_colors(nc$n)
    names(nc_pal) <- nc$names[1:nc$n]
    pal <- c(pal, nc_pal)
  }
  # Ensure all groups have colors
  for (g_name in all_groups) {
    if (!(g_name %in% names(pal))) pal[g_name] <- "#888888"
  }

  # Plot
  ggplot2::ggplot() +
    ggplot2::geom_segment(data = seg_df,
                          ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
                          color = "gray85", linewidth = 0.15, alpha = 0.4) +
    ggplot2::geom_point(data = node_df,
                        ggplot2::aes(x = x, y = y, color = group), size = 1.5, alpha = 0.8) +
    ggplot2::scale_color_manual(values = pal) +
    ggplot2::labs(title = title, color = NULL) +
    ggplot2::theme_void(base_size = 12) +
    ggplot2::theme(legend.position = "bottom",
                   plot.title = ggplot2::element_text(hjust = 0.5))
}

# ----
# Network Summary Stats
# ----

network_summary <- function(agents, network, params) {
  if (is.null(network)) return(NULL)
  n <- nrow(agents)
  denom_names <- params$denom_names

  degrees <- sapply(network, length)

  # Homophily: fraction of ties to same-religion agents
  same_frac <- sapply(1:n, function(i) {
    nbrs <- network[[i]]
    if (length(nbrs) == 0) return(NA)
    mean(agents$identity[nbrs] == agents$identity[i])
  })

  data.frame(
    metric = c("Mean Degree", "SD Degree", "Min Degree", "Max Degree",
               "Mean Homophily (All)", "Mean Homophily (Christian)",
               "Mean Homophily (NC)", "Mean Homophily (None)"),
    value = round(c(
      mean(degrees), sd(degrees), min(degrees), max(degrees),
      mean(same_frac, na.rm = TRUE),
      mean(same_frac[agents$identity %in% denom_names], na.rm = TRUE),
      mean(same_frac[!agents$identity %in% c(denom_names, "None")], na.rm = TRUE),
      mean(same_frac[agents$identity == "None"], na.rm = TRUE)
    ), 3)
  )
}
