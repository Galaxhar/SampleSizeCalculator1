# Verificacao de metodo sob um modelo de trabalho, nao validacao clinica.
# Sem dependencias externas. As funcoes nao executam ao carregar este arquivo.

simulation_wilson <- function(successes, total, level = 0.95) {
  z <- qnorm(1 - (1 - level) / 2)
  p <- successes / total
  denominator <- 1 + z^2 / total
  centre <- (p + z^2 / (2 * total)) / denominator
  half <- z * sqrt(p * (1 - p) / total + z^2 / (4 * total^2)) /
    denominator
  c(lower = max(0, centre - half), upper = min(1, centre + half))
}

simulation_stratum_counts <- function(n) {
  # Sexo 0/1 em AOS leve [5,15) e moderada [15,30).
  # Fracoes sao convencoes da simulacao, nao estimativas da populacao.
  target <- n * c(0.20, 0.20, 0.30, 0.30)
  counts <- floor(target)
  remaining <- n - sum(counts)
  if (remaining > 0L) {
    index <- order(target - counts, decreasing = TRUE)[seq_len(remaining)]
    counts[index] <- counts[index] + 1L
  }
  counts
}

simulate_one_clinical_scenario <- function(params, n, delta,
                                         loss_probability = 0,
                                         seed = params$seed) {
  stopifnot(length(n) == 1L, n == as.integer(n), n >= 8L,
            length(delta) == 1L, is.finite(delta),
            params$nsim >= 10000L, params$sd_post > 0,
            abs(params$rho) < 1, params$alpha > 0, params$alpha < 1,
            loss_probability >= 0, loss_probability < 1,
            params$covariates == 2L)
  set.seed(seed)
  repetitions <- as.integer(params$nsim)
  counts <- simulation_stratum_counts(n)
  stratum <- rep(seq_len(4L), times = 2L * counts)
  stratum_sex <- c(0, 1, 0, 1)
  lower <- c(5, 5, 15, 15)
  upper <- c(15, 15, 30, 30)
  stratum_mean <- (lower + upper) / 2
  stratum_variance <- (upper - lower)^2 / 12
  weights <- counts / n
  baseline_mean <- sum(weights * stratum_mean)
  baseline_variance <- sum(weights *
    (stratum_variance + (stratum_mean - baseline_mean)^2))
  baseline_slope <- params$rho * params$sd_post / sqrt(baseline_variance)
  residual_sd <- params$sd_post * sqrt(1 - params$rho^2)
  rejected <- logical(repetitions)
  conditional_power <- numeric(repetitions)
  valid <- logical(repetitions)
  observed_n0 <- observed_n1 <- numeric(repetitions)
  # Momentos acumulados dentro dos grupos, sem inflacao pela diferenca de medias.
  moment_xx <- moment_yy <- moment_xy <- moment_df <- 0
  negative_outcomes <- generated_outcomes <- 0L

  for (b in seq_len(repetitions)) {
    baseline <- runif(2L * n, lower[stratum], upper[stratum])
    sex <- stratum_sex[stratum]
    # Em cada estrato: bloco completo com exatamente counts[k] por braco.
    # Nao e uma implementacao da lista de randomizacao do ensaio real.
    group <- unlist(lapply(counts, function(m) {
      sample(rep(0:1, each = m), size = 2L * m, replace = FALSE)
    }), use.names = FALSE)
    outcome <- 20 - delta * group +
      baseline_slope * (baseline - baseline_mean) +
      rnorm(2L * n, mean = 0, sd = residual_sd)
    negative_outcomes <- negative_outcomes + sum(outcome < 0)
    generated_outcomes <- generated_outcomes + length(outcome)
    keep <- if (loss_probability == 0) rep(TRUE, 2L * n) else
      runif(2L * n) >= loss_probability
    baseline <- baseline[keep]
    sex <- sex[keep]
    group <- group[keep]
    outcome <- outcome[keep]
    observed_n0[b] <- sum(group == 0)
    observed_n1[b] <- sum(group == 1)

    for (arm in 0:1) {
      selected <- group == arm
      if (sum(selected) > 1L) {
        x_c <- baseline[selected] - mean(baseline[selected])
        y_c <- outcome[selected] - mean(outcome[selected])
        moment_xx <- moment_xx + sum(x_c^2)
        moment_yy <- moment_yy + sum(y_c^2)
        moment_xy <- moment_xy + sum(x_c * y_c)
        moment_df <- moment_df + sum(selected) - 1L
      }
    }
    design <- cbind(`(Intercept)` = 1, group = group,
                    baseline = baseline - baseline_mean, sex = sex)
    if (nrow(design) <= ncol(design)) next
    fit <- lm.fit(x = design, y = outcome)
    if (fit$rank != ncol(design) || fit$df.residual <= 0) next
    variance_unscaled <- chol2inv(qr.R(fit$qr))
    treatment_index <- match(2L, fit$qr$pivot)
    treatment_variance_factor <-
      variance_unscaled[treatment_index, treatment_index]
    residual_variance <- sum(fit$residuals^2) / fit$df.residual
    se <- sqrt(residual_variance * treatment_variance_factor)
    t_value <- fit$coefficients[2L] / se
    p_value <- 2 * pt(abs(t_value), df = fit$df.residual,
                      lower.tail = FALSE)
    rejected[b] <- p_value < params$alpha
    critical <- qt(1 - params$alpha / 2, df = fit$df.residual)
    ncp <- abs(delta) / (residual_sd * sqrt(treatment_variance_factor))
    conditional_power[b] <-
      pt(-critical, df = fit$df.residual, ncp = ncp) +
      pt(critical, df = fit$df.residual, ncp = ncp, lower.tail = FALSE)
    valid[b] <- TRUE
  }

  interval <- simulation_wilson(sum(rejected), repetitions)
  rejection_rate <- mean(rejected)
  mean_conditional <- mean(conditional_power)
  # Variancia dos desvios Bernoulli-p(X), util para diagnosticar a implementacao.
  discrepancy_se <- sqrt(mean(conditional_power *
                              (1 - conditional_power)) / repetitions)
  data.frame(
    scenario = if (loss_probability == 0) "avaliaveis_fixos" else "perdas_MCAR",
    hypothesis = if (delta == 0) "nula_erro_tipo_I" else "alternativa_poder",
    n_per_arm_initial = n,
    loss_probability = loss_probability,
    delta = delta,
    simulations = repetitions,
    estimable_simulations = sum(valid),
    nonestimable_simulations = sum(!valid),
    rejection_rate = rejection_rate,
    mc_se = sqrt(rejection_rate * (1 - rejection_rate) / repetitions),
    mc_ci_lower = unname(interval[1L]),
    mc_ci_upper = unname(interval[2L]),
    conditional_power_mean = mean_conditional,
    simulation_minus_conditional = rejection_rate - mean_conditional,
    discrepancy_mc_se = discrepancy_se,
    discrepancy_z = if (discrepancy_se > 0)
      (rejection_rate - mean_conditional) / discrepancy_se else NA_real_,
    conditional_power_mc_se = sd(conditional_power) / sqrt(repetitions),
    empirical_within_arm_rho = moment_xy / sqrt(moment_xx * moment_yy),
    empirical_within_arm_sd_post = sqrt(moment_yy / moment_df),
    mean_n_sham = mean(observed_n0),
    mean_n_electroacupuncture = mean(observed_n1),
    residual_sd_used = residual_sd,
    baseline_sd_population_used = sqrt(baseline_variance),
    baseline_slope_used = baseline_slope,
    negative_generated_outcome_fraction = negative_outcomes / generated_outcomes,
    seed = seed,
    stringsAsFactors = FALSE
  )
}

simulate_clinical <- function(params, sample_sizes) {
  sample_sizes <- sort(unique(as.integer(sample_sizes)))
  if (!length(sample_sizes) || anyNA(sample_sizes))
    stop("Informe tamanhos amostrais inteiros por grupo.")
  results <- vector("list", length(sample_sizes) * 2L)
  k <- 0L
  for (n in sample_sizes) {
    for (is_alternative in c(TRUE, FALSE)) {
      k <- k + 1L
      scenario_seed <- as.integer(params$seed + 1000L * n +
                                    if (is_alternative) 1L else 2L)
      message("Simulacao R: n=", n, "; ",
              if (is_alternative) "alternativa" else "nula", "; B=", params$nsim)
      results[[k]] <- simulate_one_clinical_scenario(
        params, n = n, delta = if (is_alternative) params$delta else 0,
        seed = scenario_seed)
    }
  }
  output <- do.call(rbind, results)
  if (any(output$nonestimable_simulations > 0L))
    stop("Houve ANCOVAs nao estimaveis nos cenarios principais; investigar.")
  rownames(output) <- NULL
  output
}

simulate_recruitment_mcar <- function(params, recruited_per_arm = 30L) {
  results <- lapply(c(TRUE, FALSE), function(is_alternative) {
    message("Simulacao R: recrutamento=", recruited_per_arm,
            "; perdas MCAR=", params$loss, "; ",
            if (is_alternative) "alternativa" else "nula")
    simulate_one_clinical_scenario(
      params, n = recruited_per_arm,
      delta = if (is_alternative) params$delta else 0,
      loss_probability = params$loss,
      seed = as.integer(params$seed + 900000L +
                          if (is_alternative) 1L else 2L))
  })
  output <- do.call(rbind, results)
  rownames(output) <- NULL
  output
}
