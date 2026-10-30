# ANCOVA com dois bracos de mesmo tamanho. Todas as unidades sao eventos/h.
check_scalar <- function(x, name, lower = -Inf, upper = Inf,
                         lower_open = FALSE, upper_open = FALSE) {
  if (length(x) != 1L || !is.numeric(x) || !is.finite(x) ||
      (if (lower_open) x <= lower else x < lower) ||
      (if (upper_open) x >= upper else x > upper))
    stop("Valor invalido: ", name, call. = FALSE)
}

residual_sd <- function(sd, rho = NULL, sd_type = c("post", "residual")) {
  sd_type <- match.arg(sd_type)
  check_scalar(sd, "sd", 0, lower_open = TRUE)
  if (sd_type == "residual") {
    if (!is.null(rho)) stop("DP residual: nao forneca rho; evita reducao duplicada.")
    return(sd)
  }
  check_scalar(rho, "rho", -1, 1, TRUE, TRUE)
  sd * sqrt(1 - rho^2)
}

ancova_power <- function(n, delta, sd, rho = NULL, alpha = 0.05,
                         covariates = 2L, sd_type = c("post", "residual")) {
  check_scalar(n, "n", 1)
  check_scalar(delta, "delta", 0)
  check_scalar(alpha, "alpha", 0, 1, TRUE, TRUE)
  check_scalar(covariates, "covariates", 0)
  if (n != floor(n) || covariates != floor(covariates)) stop("n e covariates devem ser inteiros.")
  df <- 2 * n - covariates - 2
  if (df <= 0) stop("Graus de liberdade residuais insuficientes.")
  sigma <- residual_sd(sd, rho, match.arg(sd_type))
  ncp <- delta / (sigma * sqrt(2 / n))
  critical <- qt(1 - alpha / 2, df)
  # Soma das duas caudas, inclusive para alternativa nula.
  pt(-critical, df, ncp = ncp) + pt(critical, df, ncp = ncp, lower.tail = FALSE)
}

normal_sample_size <- function(delta, sd, rho = NULL, power = .8, alpha = .05,
                               sd_type = c("post", "residual")) {
  check_scalar(delta, "delta", 0, lower_open = TRUE)
  check_scalar(power, "power", 0.5, 1, upper_open = TRUE)
  check_scalar(alpha, "alpha", 0, 1, TRUE, TRUE)
  sigma <- residual_sd(sd, rho, match.arg(sd_type))
  2 * (qnorm(1 - alpha / 2) + qnorm(power))^2 * sigma^2 / delta^2
}

finite_sample_size <- function(delta, sd, rho = NULL, power = .8, alpha = .05,
                               covariates = 2L, sd_type = c("post", "residual")) {
  sd_type <- match.arg(sd_type)
  check_scalar(power, "power", 0.5, 1, upper_open = TRUE)
  approximate <- normal_sample_size(delta, sd, rho, power, alpha, sd_type)
  low <- max(2L, floor((covariates + 2) / 2) + 1L)
  high <- max(low, ceiling(approximate))
  pow <- function(n) ancova_power(n, delta, sd, rho, alpha, covariates, sd_type)
  while (pow(high) < power) {
    high <- 2L * high
    if (high > 1e7) stop("Tamanho amostral excedeu limite de busca.")
  }
  while (low < high) {
    middle <- floor((low + high) / 2)
    if (pow(middle) >= power) high <- middle else low <- middle + 1L
  }
  as.integer(low)
}

inflate_losses <- function(n, loss) {
  check_scalar(n, "n", 1)
  check_scalar(loss, "loss", 0, 1, upper_open = TRUE)
  as.integer(ceiling(n / (1 - loss)))
}

clinical_results <- function(p) {
  n_z <- normal_sample_size(p$delta, p$sd_post, p$rho, p$power, p$alpha)
  n_t <- finite_sample_size(p$delta, p$sd_post, p$rho, p$power, p$alpha, p$covariates)
  n_expected <- p$recruited_per_arm * (1 - p$loss)
  n_fixed <- floor(n_expected)
  data.frame(
    sd_post = p$sd_post, rho = p$rho, delta = p$delta, alpha = p$alpha,
    target_power = p$power, loss = p$loss, covariates = p$covariates,
    sd_residual = residual_sd(p$sd_post, p$rho), n_normal_raw = n_z,
    n_normal_per_arm = ceiling(n_z), n_finite_per_arm = n_t,
    residual_df = 2L * n_t - p$covariates - 2L,
    recruit_per_arm = inflate_losses(n_t, p$loss),
    recruit_total = 2L * inflate_losses(n_t, p$loss),
    power_at_finite_n = ancova_power(n_t, p$delta, p$sd_post, p$rho, p$alpha, p$covariates),
    current_recruit_per_arm = p$recruited_per_arm,
    expected_evaluable_per_arm = n_expected,
    fixed_evaluable_for_power = n_fixed,
    power_at_expected_floor = ancova_power(n_fixed, p$delta, p$sd_post, p$rho, p$alpha, p$covariates),
    power_no_losses_current = ancova_power(p$recruited_per_arm, p$delta, p$sd_post, p$rho, p$alpha, p$covariates),
    prob_both_reach_n_current = pbinom(n_t - 1L, p$recruited_per_arm, 1 - p$loss, lower.tail = FALSE)^2,
    prob_both_reach_n_recommended = pbinom(n_t - 1L, inflate_losses(n_t, p$loss), 1 - p$loss, lower.tail = FALSE)^2
  )
}

audit_parameters <- function(p, source_data) {
  s <- source_data$sd_post[1:2]; n <- source_data$analyzed[1:2]
  equal <- sqrt(mean(s^2)); pooled <- sqrt(sum((n - 1) * s^2) / sum(n - 1))
  data.frame(
    parameter = c("DPs pos", "DP combinado pesos iguais", "DP combinado ponderado", "DP central",
                  "Correlacao basal-pos", "Diferenca alvo", "Alfa bilateral", "Poder",
                  "Perdas", "Avaliaveis aproximados", "Recrutamento proposto", "Covariaveis"),
    value = c("5.6; 11.0", format(equal, digits=10), format(pooled, digits=10),
              p$sd_post, p$rho, p$delta, p$alpha, p$power, p$loss, "25", paste0(p$recruited_per_arm,"/grupo"), "2"),
    classification = c("dado publicado", "estimativa derivada", "estimativa derivada", "hipotese de planejamento",
                       "hipotese de planejamento", "estimativa clinica preespecificada", "hipotese de planejamento",
                       "hipotese de planejamento", "hipotese de planejamento", "estimativa derivada",
                       "hipotese de planejamento", "dado documental"),
    source = c(rep("Freire 2007, Tabela 3 p.47; Figura 1 p.45",3),
               rep("Projeto original P0080; revisao docs/fundamentacao_20261030.md",8), "Projeto P0172; secao 3.10"),
    procedure = c("DPs marginais pos de acupuntura e sham; n=10 e 7 analisados",
      "sqrt((5.6^2+11^2)/2); nao e media aritmetica dos DPs",
      "sqrt((9*5.6^2+6*11^2)/15); pesos n-1; nao usar 12 alocados",
      "8.728 arredondado para 8.7; transportabilidade incerta; mantido conforme pedido",
      "Hipotese .5; apoio indireto Puhan2006: r combinado .559 derivado de DPs basal/final/mudanca; outra intervencao e visita",
      "6 eventos/h e estimativa clinica; Wang2020 MD -6.18 evidencia baixa/heterogenea; nao MCID validada",
      "Escolha do protocolo, nao estimativa de Freire", "Probabilidade de rejeicao sob alternativa; nao respondedores",
      "Retencao esperada 0.80; nao garantia; nao taxa extraida de Freire",
      "Aproximacao normal com rho=.5; amostra finita calculada separadamente",
      paste0(p$recruited_per_arm," por grupo; retencao esperada ",p$recruited_per_arm*(1-p$loss),"; n finito 26 e ceil(26/.8)=33 no cenario central"),
      "IAH basal continuo e sexo binario; gravidade nao adicionada separadamente"),
    stringsAsFactors = FALSE
  )
}
