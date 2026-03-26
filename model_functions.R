# Model 1: Free Religious Market ABM — Core Model Functions ----
# This file contains all the mechanics of the ABM: agent creation,
# conversion, retention, R dynamics, demography, network, and stats.
# Called by run_batch.R and batch_run_whole_codes.R.

# Safe Value Helpers ----
# Defensive wrappers so the model doesn't crash when a param is NULL/NA.
# safe_val returns a scalar, safe_vec returns a vector of length n.

safe_val <- function(x, default) {
  if (is.null(x) || length(x) == 0 || anyNA(x)) return(default)
  x[1]
}

safe_vec <- function(x, default, n) {
  if (is.null(x) || length(x) == 0) return(rep(default, n))
  out <- rep(default, n)
  len <- min(length(x), n)
  out[1:len] <- x[1:len]
  out[is.na(out)] <- default
  out
}

# Denomination Defaults ----
# Five Christian denominations vary on entry strictness (gatekeeping),
# retention strictness (community strength), and evangelism intensity.
# These profiles are loosely based on denominational typologies in China.

get_denomination_defaults <- function() {
  # China 1980: ~0.5% Christian total, equal split
  # Christianity given maximum evangelism advantage (ideal condition)
  # entry_strictness = gatekeeping (threshold to join)
  # strictness = community strength (retention, transmission, R boosts)
  list(
    names = c("Evangelical", "Mainline", "Catholic", "Charismatic", "Other Christian"),
    entry_strictness = c(0.2, 0.2, 0.4, 0.8, 0.3),
    strictness = c(0.7, 0.2, 0.5, 0.9, 0.3),
    evangelism = c(0.90, 0.20, 0.30, 0.90, 0.40),
    initial_pct = rep(0.001, 5)
  )
}

# Non-Christian Group Defaults ----
# Four NC religions (Buddhism, Folk Religion, Islam, Daoism) configured
# as passive competitors: no active evangelism, grow only via transmission.
# Islam has high switching cost (ethnic boundary); Folk Religion has zero.

get_nc_defaults <- function() {
  # China 1980 religious landscape
  # Key asymmetry: ALL NC groups are passive (no active evangelism)
  # Christianity has monopoly on recruitment
  list(
    names = c("Buddhism", "Folk Religion", "Islam", "Daoism", "Other religions"),
    strictness = c(0.3, 0.1, 0.9, 0.2, 0.3),
    evangelism = c(0.05, 0.00, 0.00, 0.00, 0.05),
    active = c(FALSE, FALSE, FALSE, FALSE, FALSE),
    initial_pct = c(0.08, 0.20, 0.015, 0.03, 0.02),
    conversion_threshold = c(0.2, 0.0, 1.5, 0.2, 0.2),
    transmission = c(0.60, 0.70, 0.95, 0.40, 0.70),
    switching_cost = c(0.3, 0.2, 2.0, 0.2, 0.5)
  )
}

# Default Parameters ----
# Master parameter list. Scenario presets (in utils.R) override specific
# values; everything else falls back to these defaults.

get_default_params <- function() {
  dd <- get_denomination_defaults()
  nc <- get_nc_defaults()
  
  list(
    # Time & Population
    n_agents = 5000L,
    start_year = 1980L,
    end_year = 2080L,
    timestep_years = 0.5,
    
    # R Distribution
    R_dist_type = "normal",
    R_mean = 0,
    R_sd = 1,
    R_high_threshold = 1.0,
    R_low_threshold = 0.0,
    bimodal_low_mean = -0.8,
    bimodal_high_mean = 0.8,
    bimodal_sd = 0.5,
    bimodal_mix = 0.5,
    
    # Denomination Parameters (5 Christian groups)
    denom_names = dd$names,
    denom_entry_strictness = dd$entry_strictness,
    denom_strictness = dd$strictness,
    denom_evangelism = dd$evangelism,
    denom_initial_pct = dd$initial_pct,
    
    # Non-Christian Competitors (up to 5 groups)
    n_nonchristian = 4L,
    nc_names = nc$names,
    nc_strictness = nc$strictness,
    nc_evangelism = nc$evangelism,
    nc_active = nc$active,
    nc_initial_pct = nc$initial_pct,
    nc_conversion_threshold = nc$conversion_threshold,
    nc_transmission = nc$transmission,
    nc_switching_cost = nc$switching_cost,
    
    # NC Retention (shared base rates)
    nc_exit_high = 0.003,
    nc_exit_mid = 0.015,
    nc_exit_low = 0.05,
    nc_stickiness_factor = 0.5,
    
    # R Boosts
    init_R_boost = 0.2,
    init_R_strictness_mod = 0.2,
    init_R_boost_nc = 0.15,
    convert_R_boost = 0.1,
    convert_R_strictness_mod = 0.1,
    convert_R_boost_nc = 0.1,
    cross_convert_R_boost = 0.1,
    offspring_R_boost = 0.15,
    offspring_R_strictness_mod = 0.1,
    exit_R_penalty = 0.3,
    
    # Conversion Mechanics
    base_conversion_threshold = 0.3,
    strictness_threshold_modifier = 0.8,
    base_convert_prob = 0.3,
    cross_convert_prob = 0.15,
    
    # Inter-Denominational Switching
    switch_rate = 0.05,
    switch_up_R_buffer = 0.2,
    switch_down_R_buffer = 0.3,
    switch_down_rate_multiplier = 2.0,
    
    # Retention (Christian denominations)
    base_exit_high = 0.005,
    base_exit_mid = 0.02,
    base_exit_low = 0.08,
    strictness_retention_modifier = 0.6,
    
    # R Dynamics
    R_drift_rate = 0.03,
    R_decay_none = 0.01,
    
    # Government / Regulation (free market default)
    regulation_intensity = 0.0,
    persecution_threshold = 1.0,
    persecution_impact_christian = 0.0,
    persecution_impact_nc = 0.0,
    deterrence_low_R = 0.0,
    solidarity_high_R = 0.0,
    
    # Demography
    demography_enabled = TRUE,
    turnover_rate = 0.02,
    R_heritability = 0.8,
    base_transmission = 0.8,
    strictness_transmission_modifier = 0.3,
    secular_cohort_year = 2012,
    secular_cohort_factor = 0.8,
    
    # Network
    network_enabled = FALSE,
    network_ties = 15L,
    network_christian_homophily = 0.5,
    network_nc_homophily = 0.25,
    network_new_ties_christian = 3L,
    network_new_ties_nc = 1L,
    network_weaken_christian = 2L,
    network_weaken_nc = 1L,
    network_nc_drift_weight = 0.5,
    
    # Simulation
    n_replications = 30L,
    random_seed = NULL
  )
}

# R Distribution Generator ----
# Draws initial R values for the population. Four shapes available:
# normal, bimodal, right-skewed (favorable), left-skewed (secular).
# All values clamped to [-2, 2].

generate_R <- function(n, type = "normal", params = list()) {
  R_mean <- safe_val(params$R_mean, 0)
  R_sd <- safe_val(params$R_sd, 1)
  
  R <- switch(type,
              "normal" = rnorm(n, R_mean, R_sd),
              "bimodal" = {
                mix <- safe_val(params$bimodal_mix, 0.5)
                lo <- safe_val(params$bimodal_low_mean, -0.8)
                hi <- safe_val(params$bimodal_high_mean, 0.8)
                sd_b <- safe_val(params$bimodal_sd, 0.5)
                g <- rbinom(n, 1, mix)
                ifelse(g == 0, rnorm(n, lo, sd_b), rnorm(n, hi, sd_b))
              },
              "right_skewed" = rbeta(n, 5, 2) * 4 - 2,
              "left_skewed" = rbeta(n, 2, 5) * 4 - 2,
              rnorm(n, R_mean, R_sd)
  )
  pmax(-2, pmin(2, R))
}

# Helper: active NC info ----
# Convenience function returning the count, names, and indices of
# whichever NC groups are enabled in this scenario.

get_active_nc <- function(params) {
  n_nc <- safe_val(params$n_nonchristian, 0L)
  if (n_nc == 0) return(list(n = 0, names = character(0), idx = integer(0)))
  idx <- 1:n_nc
  list(n = n_nc, names = params$nc_names[idx], idx = idx)
}

# Agent Initialization ----
# Creates the agent data.frame: assigns R values, distributes agents
# across denominations and NC groups, remainder becomes "None".
# Each agent also gets a `source` field: "born" if initialized with a
# religion, NA if None. This tracks convert vs. born-Christian later.

initialize_agents <- function(params) {
  n <- safe_val(params$n_agents, 5000L)
  R <- generate_R(n, safe_val(params$R_dist_type, "normal"), params)
  identity <- rep("None", n)
  remaining <- 1:n
  
  denom_names <- params$denom_names
  n_denoms <- length(denom_names)
  
  for (d in 1:n_denoms) {
    nd <- round(n * safe_val(params$denom_initial_pct[d], 0))
    if (nd > 0 && length(remaining) >= nd) {
      ids <- sample(remaining, nd)
      identity[ids] <- denom_names[d]
      boost <- safe_val(params$init_R_boost, 0.2) +
        params$denom_strictness[d] * safe_val(params$init_R_strictness_mod, 0.2)
      R[ids] <- pmin(2, R[ids] + boost)
      remaining <- setdiff(remaining, ids)
    }
  }
  
  nc <- get_active_nc(params)
  if (nc$n > 0) {
    for (j in nc$idx) {
      nd <- round(n * safe_val(params$nc_initial_pct[j], 0))
      if (nd > 0 && length(remaining) >= nd) {
        ids <- sample(remaining, nd)
        identity[ids] <- params$nc_names[j]
        R[ids] <- pmin(2, R[ids] + safe_val(params$init_R_boost_nc, 0.15))
        remaining <- setdiff(remaining, ids)
      }
    }
  }
  
  data.frame(
    id = 1:n, R = R, identity = identity,
    source = ifelse(identity != "None", "born", NA_character_),
    tenure = ifelse(identity != "None", sample(1:20, n, replace = TRUE), 0L),
    x = runif(n), y = runif(n),
    stringsAsFactors = FALSE
  )
}

# Network Initialization ----
# Builds an undirected adjacency list with ~k ties per agent.
# Christians cluster with co-religionists (homophily = 50%),
# NC agents cluster within their own group (25%). Bidirectional.

initialize_network <- function(agents, params) {
  n <- nrow(agents)
  k <- safe_val(params$network_ties, 15L)
  chr_h <- safe_val(params$network_christian_homophily, 0.5)
  nc_h <- safe_val(params$network_nc_homophily, 0.25)
  denom_names <- params$denom_names
  identities <- agents$identity
  
  # Build group index pools
  chr_pool <- which(identities %in% denom_names)
  nc <- get_active_nc(params)
  nc_pools <- if (nc$n > 0) {
    setNames(lapply(nc$names, function(nm) which(identities == nm)), nc$names)
  } else list()
  all_ids <- 1:n
  
  # Allocate adjacency list
  adj <- vector("list", n)
  
  for (i in 1:n) {
    id_i <- identities[i]
    is_chr <- id_i %in% denom_names
    is_nc <- !is_chr && id_i != "None"
    
    h <- if (is_chr) chr_h else if (is_nc) nc_h else 0
    
    # Christians cluster with all Christians; NC with own group
    if (is_chr) {
      same_pool <- setdiff(chr_pool, i)
    } else if (is_nc) {
      same_pool <- setdiff(nc_pools[[id_i]], i)
    } else {
      same_pool <- integer(0)
    }
    
    n_homo <- min(round(k * h), length(same_pool))
    n_rand <- k - n_homo
    
    homo_ties <- if (n_homo > 0) sample(same_pool, n_homo) else integer(0)
    rand_pool <- setdiff(all_ids, c(i, homo_ties))
    rand_ties <- if (n_rand > 0 && length(rand_pool) >= n_rand) {
      sample(rand_pool, n_rand)
    } else if (length(rand_pool) > 0) {
      sample(rand_pool, min(n_rand, length(rand_pool)))
    } else integer(0)
    
    adj[[i]] <- c(homo_ties, rand_ties)
  }
  
  # Ensure bidirectional
  for (i in 1:n) {
    for (j in adj[[i]]) {
      if (!(i %in% adj[[j]])) adj[[j]] <- c(adj[[j]], i)
    }
  }
  
  adj
}

# Network Rewiring on Conversion ----
# When an agent converts, they gain new co-religionist ties and drop
# some out-group ties. This produces endogenous clustering over time.

rewire_on_conversion <- function(network, converted_ids, new_identities,
                                 agents, params) {
  if (is.null(network) || length(converted_ids) == 0) return(network)
  denom_names <- params$denom_names
  n_new_chr <- safe_val(params$network_new_ties_christian, 3L)
  n_new_nc <- safe_val(params$network_new_ties_nc, 1L)
  n_weak_chr <- safe_val(params$network_weaken_christian, 2L)
  n_weak_nc <- safe_val(params$network_weaken_nc, 1L)
  
  for (idx in seq_along(converted_ids)) {
    aid <- converted_ids[idx]
    new_id <- new_identities[idx]
    is_chr <- new_id %in% denom_names
    
    n_add <- if (is_chr) n_new_chr else n_new_nc
    n_weak <- if (is_chr) n_weak_chr else n_weak_nc
    
    # Add co-religionist ties
    if (is_chr) {
      pool <- which(agents$identity %in% denom_names)
    } else {
      pool <- which(agents$identity == new_id)
    }
    pool <- setdiff(pool, c(aid, network[[aid]]))
    
    n_actual <- min(n_add, length(pool))
    if (n_actual > 0) {
      new_ties <- sample(pool, n_actual)
      network[[aid]] <- c(network[[aid]], new_ties)
      for (nt in new_ties) network[[nt]] <- c(network[[nt]], aid)
    }
    
    # Remove some non-co-religionist ties
    current <- network[[aid]]
    if (is_chr) {
      removable <- current[!(agents$identity[current] %in% denom_names)]
    } else {
      removable <- current[agents$identity[current] != new_id]
    }
    n_rm <- min(n_weak, length(removable))
    if (n_rm > 0) {
      to_rm <- sample(removable, n_rm)
      network[[aid]] <- setdiff(network[[aid]], to_rm)
      for (tr in to_rm) network[[tr]] <- setdiff(network[[tr]], aid)
    }
  }
  
  network
}

# Persecution Check ----
# Returns TRUE if Christian share exceeds the persecution threshold.
# When active, evangelism is suppressed and R is pushed in both
# directions (deterrence for marginal, solidarity for committed).

check_persecution <- function(agents, params) {
  if (is.null(agents) || nrow(agents) == 0) return(FALSE)
  denom_names <- params$denom_names
  christian_pct <- mean(agents$identity %in% denom_names, na.rm = TRUE)
  thresh <- safe_val(params$persecution_threshold, 1.0)
  result <- christian_pct > thresh
  if (is.na(result) || length(result) != 1) return(FALSE)
  result
}

# Conversion: None -> Religion ----
# Unaffiliated agents are exposed to religious groups proportional to
# group size × evangelism. They convert if R > entry threshold, with
# probability scaling with the R gap. Converts are tagged source="convert".

process_conversion <- function(agents, params, persecution_active, network = NULL) {
  n <- nrow(agents)
  none_idx <- which(agents$identity == "None")
  if (length(none_idx) == 0) return(list(agents = agents, network = network))
  
  n_none <- length(none_idx)
  R_none <- agents$R[none_idx]
  reg <- safe_val(params$regulation_intensity, 0)
  persecution_active <- isTRUE(persecution_active)
  use_net <- isTRUE(params$network_enabled) && !is.null(network)
  
  denom_names <- params$denom_names
  n_denoms <- length(denom_names)
  
  evangelism <- params$denom_evangelism * (1 - reg)
  if (persecution_active) {
    evangelism <- evangelism * (1 - safe_val(params$persecution_impact_christian, 0))
  }
  thresholds <- safe_val(params$base_conversion_threshold, 0.3) +
    safe_vec(params$denom_entry_strictness, 0.3, 5) *
    safe_val(params$strictness_threshold_modifier, 0.8)
  
  nc <- get_active_nc(params)
  nc_evang_vec <- numeric(max(nc$n, 1))
  nc_thresh_vec <- numeric(max(nc$n, 1))
  if (nc$n > 0) {
    for (j in 1:nc$n) {
      ji <- nc$idx[j]
      if (!isTRUE(params$nc_active[ji])) next
      nc_evang_vec[j] <- safe_val(params$nc_evangelism[ji], 0.10) * (1 - reg)
      if (persecution_active) {
        nc_evang_vec[j] <- nc_evang_vec[j] * (1 - safe_val(params$persecution_impact_nc, 0))
      }
      nc_thresh_vec[j] <- safe_val(params$nc_conversion_threshold[ji], 0.2)
    }
  }
  
  # Group names and thresholds
  n_groups <- n_denoms + nc$n
  all_names <- c(denom_names, if (nc$n > 0) nc$names else character(0))
  all_thresh <- c(thresholds, if (nc$n > 0) nc_thresh_vec[1:nc$n] else numeric(0))
  
  if (use_net) {
    # Network: local exposure from neighbors
    exposure_mat <- matrix(0, nrow = n_none, ncol = n_groups)
    for (ii in seq_len(n_none)) {
      aid <- none_idx[ii]
      nbrs <- network[[aid]]
      if (length(nbrs) == 0) next
      nbr_ids <- agents$identity[nbrs]
      n_nbrs <- length(nbrs)
      for (d in 1:n_denoms) {
        nd <- sum(nbr_ids == denom_names[d])
        exposure_mat[ii, d] <- (nd / n_nbrs) * evangelism[d]
      }
      if (nc$n > 0) {
        for (j in 1:nc$n) {
          if (nc_evang_vec[j] == 0) next
          nd <- sum(nbr_ids == nc$names[j])
          exposure_mat[ii, n_denoms + j] <- (nd / n_nbrs) * nc_evang_vec[j]
        }
      }
    }
  } else {
    # Global mean-field exposure
    shares <- sapply(all_names, function(g) sum(agents$identity == g)) / n
    all_evang <- c(evangelism, if (nc$n > 0) nc_evang_vec[1:nc$n] else numeric(0))
    exposure_vec <- shares * all_evang
    exposure_mat <- matrix(rep(exposure_vec, each = n_none), nrow = n_none)
  }
  
  # Conversion probabilities
  threshold_mat <- matrix(rep(all_thresh, each = n_none), nrow = n_none)
  R_mat <- matrix(rep(R_none, n_groups), nrow = n_none)
  eligible <- R_mat > threshold_mat
  r_gap <- R_mat - threshold_mat
  bp <- safe_val(params$base_convert_prob, 0.3)
  conv_probs <- bp * pmax(0, 1 + r_gap) * exposure_mat * eligible
  
  total_prob <- rowSums(conv_probs)
  converts <- runif(n_none) < pmin(1, total_prob)
  if (sum(converts) == 0) return(list(agents = agents, network = network))
  
  convert_idx <- none_idx[converts]
  cp <- conv_probs[converts, , drop = FALSE]
  rs <- rowSums(cp)
  rs[rs == 0] <- 1
  cp_norm <- cp / rs
  
  chosen <- apply(cp_norm, 1, function(p) {
    sample(all_names, 1, prob = pmax(p, 1e-10))
  })
  
  agents$identity[convert_idx] <- chosen
  agents$tenure[convert_idx] <- 0L
  agents$source[convert_idx] <- "convert"
  
  # R boosts
  for (d in 1:n_denoms) {
    mask <- convert_idx[chosen == denom_names[d]]
    if (length(mask) > 0) {
      boost <- safe_val(params$convert_R_boost, 0.1) +
        params$denom_strictness[d] * safe_val(params$convert_R_strictness_mod, 0.1)
      agents$R[mask] <- pmin(2, agents$R[mask] + boost)
    }
  }
  if (nc$n > 0) {
    nc_boost <- safe_val(params$convert_R_boost_nc, 0.1)
    for (j in 1:nc$n) {
      mask <- convert_idx[chosen == nc$names[j]]
      if (length(mask) > 0) agents$R[mask] <- pmin(2, agents$R[mask] + nc_boost)
    }
  }
  
  # Network rewiring
  if (use_net) {
    network <- rewire_on_conversion(network, convert_idx, chosen, agents, params)
  }
  
  list(agents = agents, network = network)
}

# Cross-Religion Conversion: NC -> Christian ----
# NC members may convert to Christianity through the same exposure
# mechanism but with an additional switching cost barrier.
# The reverse (Christian -> NC) is not modeled. Tagged source="convert".

process_cross_religion_conversion <- function(agents, params, persecution_active,
                                              network = NULL) {
  nc <- get_active_nc(params)
  if (nc$n == 0) return(list(agents = agents, network = network))
  
  n <- nrow(agents)
  nc_idx <- which(agents$identity %in% nc$names)
  if (length(nc_idx) == 0) return(list(agents = agents, network = network))
  
  n_nc <- length(nc_idx)
  R_nc <- agents$R[nc_idx]
  reg <- safe_val(params$regulation_intensity, 0)
  persecution_active <- isTRUE(persecution_active)
  use_net <- isTRUE(params$network_enabled) && !is.null(network)
  
  denom_names <- params$denom_names
  n_denoms <- length(denom_names)
  
  evangelism <- params$denom_evangelism * (1 - reg)
  if (persecution_active) {
    evangelism <- evangelism * (1 - safe_val(params$persecution_impact_christian, 0))
  }
  
  base_thresholds <- safe_val(params$base_conversion_threshold, 0.3) +
    safe_vec(params$denom_entry_strictness, 0.3, 5) *
    safe_val(params$strictness_threshold_modifier, 0.8)
  
  # Per-agent switching cost
  agent_nc_group <- match(agents$identity[nc_idx], nc$names)
  sc_vec <- safe_vec(params$nc_switching_cost, 0.5, 5)
  agent_switch_cost <- sc_vec[agent_nc_group]
  
  threshold_mat <- matrix(rep(base_thresholds, each = n_nc), nrow = n_nc) +
    matrix(rep(agent_switch_cost, n_denoms), nrow = n_nc)
  
  if (use_net) {
    # Network: local exposure
    exposure_mat <- matrix(0, nrow = n_nc, ncol = n_denoms)
    for (ii in seq_len(n_nc)) {
      aid <- nc_idx[ii]
      nbrs <- network[[aid]]
      if (length(nbrs) == 0) next
      nbr_ids <- agents$identity[nbrs]
      n_nbrs <- length(nbrs)
      for (d in 1:n_denoms) {
        nd <- sum(nbr_ids == denom_names[d])
        exposure_mat[ii, d] <- (nd / n_nbrs) * evangelism[d]
      }
    }
  } else {
    shares <- sapply(denom_names, function(d) sum(agents$identity == d)) / n
    exposure_mat <- matrix(rep(shares * evangelism, each = n_nc), nrow = n_nc)
  }
  
  R_mat <- matrix(rep(R_nc, n_denoms), nrow = n_nc)
  eligible <- R_mat > threshold_mat
  r_gap <- R_mat - threshold_mat
  cp <- safe_val(params$cross_convert_prob, 0.15)
  conv_probs <- cp * pmax(0, 1 + r_gap) * exposure_mat * eligible
  
  total_prob <- rowSums(conv_probs)
  converts <- runif(n_nc) < pmin(1, total_prob)
  if (sum(converts) == 0) return(list(agents = agents, network = network))
  
  convert_idx <- nc_idx[converts]
  cprob <- conv_probs[converts, , drop = FALSE]
  rs <- rowSums(cprob)
  rs[rs == 0] <- 1
  cprob_norm <- cprob / rs
  
  chosen <- apply(cprob_norm, 1, function(p) {
    sample(denom_names, 1, prob = pmax(p, 1e-10))
  })
  
  agents$identity[convert_idx] <- chosen
  agents$tenure[convert_idx] <- 0L
  agents$source[convert_idx] <- "convert"
  agents$R[convert_idx] <- pmin(2, agents$R[convert_idx] +
                                  safe_val(params$cross_convert_R_boost, 0.1))
  
  if (use_net) {
    network <- rewire_on_conversion(network, convert_idx, chosen, agents, params)
  }
  
  list(agents = agents, network = network)
}

# Inter-Denominational Switching ----
# Christians may move between denominations based on fit between their
# R and each denomination's strictness. High-R agents drift toward
# stricter churches; low-R agents drift toward lenient ones.

process_switching <- function(agents, params) {
  denom_names <- params$denom_names
  n_denoms <- length(denom_names)
  if (n_denoms < 2) return(agents)
  
  strictness <- params$denom_strictness
  entry_strictness <- safe_vec(params$denom_entry_strictness, 0.3, n_denoms)
  thresholds <- safe_val(params$base_conversion_threshold, 0.3) +
    entry_strictness * safe_val(params$strictness_threshold_modifier, 0.8)
  switch_rate <- safe_val(params$switch_rate, 0.05)
  up_buffer <- safe_val(params$switch_up_R_buffer, 0.2)
  down_buffer <- safe_val(params$switch_down_R_buffer, 0.3)
  down_mult <- safe_val(params$switch_down_rate_multiplier, 2.0)
  
  christian_idx <- which(agents$identity %in% denom_names)
  if (length(christian_idx) == 0) return(agents)
  
  n_christians <- length(christian_idx)
  denom_shares <- sapply(denom_names, function(d) sum(agents$identity == d)) /
    max(1, n_christians)
  
  curr_identities <- agents$identity[christian_idx]
  curr_R <- agents$R[christian_idx]
  denom_idx <- match(curr_identities, denom_names)
  curr_strict <- strictness[denom_idx]
  curr_thresh <- thresholds[denom_idx]
  new_identities <- curr_identities
  
  for (i in 1:n_christians) {
    my_strict <- curr_strict[i]
    my_R <- curr_R[i]
    
    stricter <- which(strictness > my_strict & my_R > (thresholds + up_buffer))
    if (length(stricter) > 0) {
      probs <- denom_shares[stricter] * switch_rate
      if (sum(probs) > 0 && runif(1) < sum(probs)) {
        new_identities[i] <- sample(denom_names[stricter], 1,
                                    prob = probs / sum(probs))
        next
      }
    }
    
    di <- denom_idx[i]
    if (my_R < (curr_thresh[i] - down_buffer)) {
      lenient <- which(strictness < strictness[di])
      if (length(lenient) > 0) {
        probs <- denom_shares[lenient] * switch_rate * down_mult
        if (sum(probs) > 0 && runif(1) < sum(probs)) {
          new_identities[i] <- sample(denom_names[lenient], 1,
                                      prob = probs / sum(probs))
        }
      }
    }
  }
  
  switched <- new_identities != curr_identities
  if (any(switched)) {
    agents$identity[christian_idx[switched]] <- new_identities[switched]
    agents$tenure[christian_idx[switched]] <- 0L
  }
  
  agents
}

# Retention ----
# Religious agents may exit to "None" each timestep. Exit probability
# depends on R category (high/mid/low) and the group's retention
# strictness. Exiting agents get source reset to NA and an R penalty.

process_retention <- function(agents, params) {
  n <- nrow(agents)
  religious_idx <- which(agents$identity != "None")
  if (length(religious_idx) == 0) return(agents)
  
  high_t <- safe_val(params$R_high_threshold, 1.0)
  low_t <- safe_val(params$R_low_threshold, 0.0)
  denom_names <- params$denom_names
  strictness <- params$denom_strictness
  ret_mod <- safe_val(params$strictness_retention_modifier, 0.6)
  nc <- get_active_nc(params)
  
  ids <- agents$identity[religious_idx]
  Rs <- agents$R[religious_idx]
  nr <- length(religious_idx)
  r_cat <- ifelse(Rs > high_t, 1L, ifelse(Rs > low_t, 2L, 3L))
  
  base_exits <- c(
    safe_val(params$base_exit_high, 0.005),
    safe_val(params$base_exit_mid, 0.02),
    safe_val(params$base_exit_low, 0.08))
  nc_exits <- c(
    safe_val(params$nc_exit_high, 0.003),
    safe_val(params$nc_exit_mid, 0.015),
    safe_val(params$nc_exit_low, 0.05))
  
  exit_rates <- numeric(nr)
  
  is_christian <- ids %in% denom_names
  if (any(is_christian)) {
    di <- match(ids[is_christian], denom_names)
    ds <- strictness[di]
    exit_rates[is_christian] <- base_exits[r_cat[is_christian]] * (1 - ds * ret_mod)
  }
  
  if (nc$n > 0) {
    nc_sticky <- safe_val(params$nc_stickiness_factor, 0.5)
    for (j in 1:nc$n) {
      ji <- nc$idx[j]
      is_this_nc <- ids == nc$names[j]
      if (!any(is_this_nc)) next
      s <- safe_val(params$nc_strictness[ji], 0.3)
      exit_rates[is_this_nc] <- nc_exits[r_cat[is_this_nc]] * (1 - s * ret_mod)
      sticky <- is_this_nc & Rs > 0
      exit_rates[sticky] <- exit_rates[sticky] * nc_sticky
    }
  }
  
  exits <- runif(nr) < exit_rates
  if (any(exits)) {
    exit_idx <- religious_idx[exits]
    agents$identity[exit_idx] <- "None"
    agents$tenure[exit_idx] <- 0L
    agents$source[exit_idx] <- NA_character_
    agents$R[exit_idx] <- pmax(-2, agents$R[exit_idx] -
                                 safe_val(params$exit_R_penalty, 0.3))
  }
  
  survive_idx <- religious_idx[!exits]
  agents$tenure[survive_idx] <- agents$tenure[survive_idx] + 1L
  
  agents
}

# R Dynamics ----
# Two forces: (1) Unaffiliated agents' R decays toward secular baseline.
# (2) Religious agents' R drifts toward their co-religionists' mean
# (social reinforcement, local if network is on). Under persecution,
# low-R Christians get a deterrence push, high-R get solidarity boost.

process_R_dynamics <- function(agents, params, persecution_active, network = NULL) {
  n <- nrow(agents)
  if (n == 0) return(agents)
  
  decay <- safe_val(params$R_decay_none, 0.01)
  drift <- safe_val(params$R_drift_rate, 0.03)
  persecution_active <- isTRUE(persecution_active)
  use_net <- isTRUE(params$network_enabled) && !is.null(network)
  nc_drift_w <- safe_val(params$network_nc_drift_weight, 0.5)
  denom_names <- params$denom_names
  
  # Global group means (always needed as fallback)
  mean_R <- tapply(agents$R, agents$identity, mean, na.rm = TRUE)
  
  is_none <- agents$identity == "None"
  agents$R[is_none] <- agents$R[is_none] - decay
  
  religious_idx <- which(!is_none)
  if (length(religious_idx) > 0) {
    if (use_net) {
      # Network: drift toward same-religion neighbor mean
      rel_ids <- agents$identity[religious_idx]
      rel_R <- agents$R[religious_idx]
      global_means <- as.numeric(mean_R[rel_ids])
      global_means[is.na(global_means)] <- rel_R[is.na(global_means)]
      
      nbr_means <- sapply(religious_idx, function(i) {
        nbrs <- network[[i]]
        same <- nbrs[agents$identity[nbrs] == agents$identity[i]]
        if (length(same) > 0) mean(agents$R[same]) else NA
      })
      na_mask <- is.na(nbr_means)
      nbr_means[na_mask] <- global_means[na_mask]
      
      is_chr <- rel_ids %in% denom_names
      w <- ifelse(is_chr, 1.0, nc_drift_w)
      targets <- w * nbr_means + (1 - w) * global_means
      agents$R[religious_idx] <- rel_R + drift * (targets - rel_R)
    } else {
      # Global mean-field drift
      group_means <- mean_R[agents$identity[religious_idx]]
      valid <- !is.na(group_means)
      idx_valid <- religious_idx[valid]
      gm <- as.numeric(group_means[valid])
      agents$R[idx_valid] <- agents$R[idx_valid] + drift * (gm - agents$R[idx_valid])
    }
  }
  
  # Persecution effects
  if (persecution_active) {
    high_t <- safe_val(params$R_high_threshold, 1.0)
    low_t <- safe_val(params$R_low_threshold, 0.0)
    deter <- safe_val(params$deterrence_low_R, 0)
    solid <- safe_val(params$solidarity_high_R, 0)
    
    christian_idx <- which(agents$identity %in% denom_names)
    if (length(christian_idx) > 0) {
      cR <- agents$R[christian_idx]
      low_mask <- cR <= low_t
      agents$R[christian_idx[low_mask]] <- agents$R[christian_idx[low_mask]] + deter
      high_mask <- cR > high_t
      agents$R[christian_idx[high_mask]] <- agents$R[christian_idx[high_mask]] + solid
    }
  }
  
  agents$R <- pmax(-2, pmin(2, agents$R))
  agents
}

# Demography ----
# 2% of agents replaced per timestep (~25-year generational cycle).
# Children inherit parent's R (with heritability noise) and religion
# (probabilistically, modified by strictness). After 2012, transmission
# drops by the secular cohort factor. Offspring tagged source="born".

process_demography <- function(agents, params, current_time, network = NULL) {
  if (!isTRUE(params$demography_enabled)) {
    return(list(agents = agents, network = network))
  }
  n <- nrow(agents)
  if (n == 0) return(list(agents = agents, network = network))
  
  n_turn <- round(n * safe_val(params$turnover_rate, 0.02))
  if (n_turn == 0) return(list(agents = agents, network = network))
  
  denom_names <- params$denom_names
  strictness <- params$denom_strictness
  base_trans <- safe_val(params$base_transmission, 0.8)
  trans_mod <- safe_val(params$strictness_transmission_modifier, 0.3)
  R_mean <- safe_val(params$R_mean, 0)
  R_sd <- safe_val(params$R_sd, 1)
  h <- safe_val(params$R_heritability, 0.8)
  off_boost <- safe_val(params$offspring_R_boost, 0.15)
  off_s_mod <- safe_val(params$offspring_R_strictness_mod, 0.1)
  sec_year <- safe_val(params$secular_cohort_year, 2012)
  sec_factor <- safe_val(params$secular_cohort_factor, 0.8)
  use_net <- isTRUE(params$network_enabled) && !is.null(network)
  nc <- get_active_nc(params)
  
  ids <- sample(1:n, min(n_turn, n))
  parent_ids <- agents$identity[ids]
  parent_R <- agents$R[ids]
  
  new_R <- h * parent_R + (1 - h) * rnorm(length(ids), R_mean, R_sd)
  new_R <- pmax(-2, pmin(2, new_R))
  new_identity <- rep("None", length(ids))
  new_source <- rep(NA_character_, length(ids))
  
  for (i in seq_along(ids)) {
    pid <- parent_ids[i]
    if (pid == "None") next
    
    di <- match(pid, denom_names)
    if (!is.na(di)) {
      tp <- base_trans + strictness[di] * trans_mod
      if (!is.null(current_time) && current_time >= sec_year) tp <- tp * sec_factor
      if (runif(1) < tp) {
        new_identity[i] <- pid
        new_source[i] <- "born"
        new_R[i] <- pmin(2, new_R[i] + off_boost + strictness[di] * off_s_mod)
      }
      next
    }
    
    if (nc$n > 0) {
      ji <- match(pid, nc$names)
      if (!is.na(ji)) {
        nc_trans <- safe_val(params$nc_transmission[nc$idx[ji]], 0.75)
        if (!is.null(current_time) && current_time >= sec_year) nc_trans <- nc_trans * sec_factor
        if (runif(1) < nc_trans) {
          new_identity[i] <- pid
          new_source[i] <- "born"
          new_R[i] <- pmin(2, new_R[i] + off_boost)
        }
      }
    }
  }
  
  agents$R[ids] <- new_R
  agents$identity[ids] <- new_identity
  agents$source[ids] <- new_source
  agents$tenure[ids] <- 0L
  
  # Network: new agent inherits ~half parent ties, adds random
  if (use_net) {
    k <- safe_val(params$network_ties, 15L)
    for (aid in ids) {
      old_ties <- network[[aid]]
      n_keep <- max(1L, round(length(old_ties) * 0.5))
      keep <- if (length(old_ties) > 0) {
        sample(old_ties, min(n_keep, length(old_ties)))
      } else integer(0)
      dropped <- setdiff(old_ties, keep)
      for (dr in dropped) network[[dr]] <- setdiff(network[[dr]], aid)
      n_new <- max(0L, k - length(keep))
      pool <- setdiff(1:n, c(aid, keep))
      new_ties <- if (n_new > 0 && length(pool) >= n_new) {
        sample(pool, n_new)
      } else integer(0)
      network[[aid]] <- c(keep, new_ties)
      for (nt in new_ties) network[[nt]] <- c(network[[nt]], aid)
    }
  }
  
  list(agents = agents, network = network)
}

# Compute Statistics ----
# Snapshot of the population at one timestep: counts and percentages for
# each denomination, NC group, and None; R composition (high/mid/low);
# mean R by group; and the convert share among Christians.

compute_stats <- function(agents, params, current_time, persecution_active) {
  n <- nrow(agents)
  denom_names <- params$denom_names
  nc <- get_active_nc(params)
  persecution_active <- isTRUE(persecution_active)
  
  stats <- list(time = current_time, n_total = n,
                persecution_active = persecution_active)
  
  for (d in denom_names) {
    key <- gsub(" ", "_", tolower(d))
    cnt <- sum(agents$identity == d)
    stats[[paste0(key, "_n")]] <- cnt
    stats[[paste0(key, "_pct")]] <- cnt / n
  }
  
  is_christian <- agents$identity %in% denom_names
  stats$christian_n <- sum(is_christian)
  stats$christian_pct <- stats$christian_n / n
  stats$christian_convert_pct <- if (stats$christian_n > 0) {
    mean(agents$source[is_christian] == "convert", na.rm = TRUE)
  } else NA
  
  for (j in 1:5) {
    if (nc$n >= j) {
      cnt <- sum(agents$identity == nc$names[j])
      stats[[paste0("nc_", j, "_n")]] <- cnt
      stats[[paste0("nc_", j, "_pct")]] <- cnt / n
    } else {
      stats[[paste0("nc_", j, "_n")]] <- 0L
      stats[[paste0("nc_", j, "_pct")]] <- 0
    }
  }
  
  nc_all <- if (nc$n > 0) sum(agents$identity %in% nc$names) else 0L
  stats$total_nc_n <- nc_all
  stats$total_nc_pct <- nc_all / n
  stats$none_n <- sum(agents$identity == "None")
  stats$none_pct <- stats$none_n / n
  stats$total_religious_pct <- 1 - stats$none_pct
  
  high_t <- safe_val(params$R_high_threshold, 1.0)
  low_t <- safe_val(params$R_low_threshold, 0.0)
  cR <- agents$R[is_christian]
  if (length(cR) > 0) {
    stats$christian_R_mean <- mean(cR)
    stats$christian_R_high_pct <- mean(cR > high_t)
    stats$christian_R_mid_pct <- mean(cR > low_t & cR <= high_t)
    stats$christian_R_low_pct <- mean(cR <= low_t)
  } else {
    stats$christian_R_mean <- NA
    stats$christian_R_high_pct <- NA
    stats$christian_R_mid_pct <- NA
    stats$christian_R_low_pct <- NA
  }
  
  for (d in denom_names) {
    key <- gsub(" ", "_", tolower(d))
    dR <- agents$R[agents$identity == d]
    stats[[paste0(key, "_R_mean")]] <- if (length(dR) > 0) mean(dR) else NA
  }
  
  stats$R_mean <- mean(agents$R)
  stats
}

# Run Single Simulation ----
# One full run: initialize agents (and network), then loop through
# timesteps executing the seven processes in order. Returns the
# time-series data.frame and the final agent state.

run_simulation <- function(params = NULL, progress_callback = NULL) {
  if (is.null(params)) params <- get_default_params()
  
  seed <- params$random_seed
  if (!is.null(seed) && !is.na(seed)) set.seed(seed)
  
  agents <- initialize_agents(params)
  network <- if (isTRUE(params$network_enabled)) {
    initialize_network(agents, params)
  } else NULL
  
  start_year <- safe_val(params$start_year, 1980)
  end_year <- safe_val(params$end_year, 2080)
  ts <- safe_val(params$timestep_years, 0.5)
  n_ts <- max(1L, as.integer(ceiling((end_year - start_year) / ts)))
  
  results <- vector("list", n_ts)
  
  for (t in 1:n_ts) {
    tm <- start_year + (t - 1) * ts
    pa <- check_persecution(agents, params)
    
    res <- process_conversion(agents, params, pa, network)
    agents <- res$agents; network <- res$network
    
    res <- process_cross_religion_conversion(agents, params, pa, network)
    agents <- res$agents; network <- res$network
    
    agents <- process_switching(agents, params)
    agents <- process_retention(agents, params)
    agents <- process_R_dynamics(agents, params, pa, network)
    
    res <- process_demography(agents, params, tm, network)
    agents <- res$agents; network <- res$network
    
    results[[t]] <- compute_stats(agents, params, tm, pa)
    if (!is.null(progress_callback)) progress_callback(t / n_ts)
  }
  
  results_df <- do.call(rbind, lapply(results, as.data.frame))
  list(results = results_df, final_agents = agents, params = params,
       final_network = network)
}

# Batch Replications ----
# Runs n_reps simulations (parallel when possible), then aggregates
# into a summary: means, SDs, 10th-90th percentile bands, and the
# mean convert share across replications at each timestep.

run_replications <- function(params, progress_callback = NULL, n_cores = NULL) {
  n_reps <- safe_val(params$n_replications, 30L)
  base_seed <- params$random_seed
  
  # Decide parallel vs sequential
  use_parallel <- FALSE
  if (is.null(n_cores)) {
    n_cores <- max(1L, parallel::detectCores() - 1L)
  }
  if (n_cores > 1 && n_reps > 1) {
    use_parallel <- TRUE
  }
  
  # Build seed list
  seeds <- vapply(1:n_reps, function(rep) {
    if (is.null(base_seed)) rep * 1000L else base_seed + rep - 1L
  }, integer(1))
  
  if (use_parallel) {
    cat("  Parallel: ", n_cores, " cores x ", n_reps, " reps\n", sep = "")
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    
    # Export functions to workers
    parallel::clusterExport(cl, ls(envir = globalenv()), envir = globalenv())
    
    worker_fn <- function(rep_info) {
      rep_idx <- rep_info$rep
      p <- rep_info$params
      p$random_seed <- rep_info$seed
      sim <- run_simulation(p)
      sim$results$replication <- rep_idx
      sim$results
    }
    
    tasks <- lapply(1:n_reps, function(i) {
      list(rep = i, params = params, seed = seeds[i])
    })
    
    all_results <- parallel::parLapply(cl, tasks, worker_fn)
  } else {
    # Sequential fallback
    all_results <- vector("list", n_reps)
    for (rep in 1:n_reps) {
      params$random_seed <- seeds[rep]
      sim <- run_simulation(params, progress_callback = function(p) {
        if (!is.null(progress_callback)) {
          overall <- ((rep - 1) + p) / n_reps
          progress_callback(overall, rep, n_reps)
        }
      })
      sim$results$replication <- rep
      all_results[[rep]] <- sim$results
    }
  }
  
  combined <- do.call(rbind, all_results)
  
  summary_df <- combined |>
    dplyr::group_by(time) |>
    dplyr::summarize(
      christian_pct_mean = mean(christian_pct, na.rm = TRUE),
      christian_pct_sd = sd(christian_pct, na.rm = TRUE),
      christian_pct_lo = quantile(christian_pct, 0.1, na.rm = TRUE),
      christian_pct_hi = quantile(christian_pct, 0.9, na.rm = TRUE),
      total_nc_pct_mean = mean(total_nc_pct, na.rm = TRUE),
      none_pct_mean = mean(none_pct, na.rm = TRUE),
      christian_R_mean = mean(christian_R_mean, na.rm = TRUE),
      christian_convert_pct_mean = mean(christian_convert_pct, na.rm = TRUE),
      persecution_pct = mean(persecution_active, na.rm = TRUE),
      .groups = "drop"
    )
  
  list(all_runs = combined, summary = summary_df, params = params)
}