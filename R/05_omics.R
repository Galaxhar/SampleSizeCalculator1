# Planejamento exploratorio omico, exclusivamente com R base/stats.
# Nenhum parametro do IAH e reutilizado. Source deste arquivo nao executa analises.

omics_status <- function() {
  data.frame(
    assay = c("plasma_proteomics", "saliva_proteomics", "saliva_peptidomics"),
    unidade_inferencial = "participante independente com medidas pareadas",
    dados_individuais_disponiveis = FALSE,
    n_definitivo = NA_integer_,
    status = "Pendente: abundancias individuais, QC, variancias e escolhas cientificas",
    stringsAsFactors = FALSE
  )
}

omics_columns <- function() {
  c("participant_id", "group", "visit", "assay", "sample_id", "analyte_id",
    "analyte_level", "technical_replicate", "abundance", "scale",
    "normalization", "prep_batch", "ms_batch", "missing_reason",
    "identification_qvalue", "qc_pass")
}

validate_omics <- function(x) {
  if (!is.data.frame(x)) stop("Forneca um data.frame de abundancias individuais.")
  absent <- setdiff(omics_columns(), names(x))
  if (length(absent)) stop("Colunas ausentes: ", paste(absent, collapse = ", "))
  if (!nrow(x)) stop("Planilha vazia: nao ha dados laboratoriais para estimar parametros.")
  required <- setdiff(omics_columns(), c("abundance", "missing_reason", "identification_qvalue"))
  for (nm in required) {
    if (any(is.na(x[[nm]]) | trimws(as.character(x[[nm]])) == ""))
      stop("Campo obrigatorio vazio: ", nm)
  }
  if (!all(x$group %in% c("sham", "EA"))) stop("group deve ser sham ou EA.")
  if (!all(x$visit %in% c("T0", "T1", "T2"))) stop("visit deve ser T0, T1 ou T2.")
  allowed <- omics_status()$assay
  if (length(unique(x$assay)) != 1L || !all(x$assay %in% allowed))
    stop("Analise uma unica modalidade omica por vez.")
  level <- if (x$assay[1L] == "saliva_peptidomics") "endogenous_peptide" else "protein"
  if (!all(x$analyte_level == level))
    stop("Use abundancia proteica validada ou peptideo endogeno; nao misture features tripticas.")
  if (length(unique(x$scale)) != 1L || !all(x$scale %in% c("raw_positive", "log2")))
    stop("Uma escala por arquivo: raw_positive ou log2.")
  if (length(unique(x$normalization)) != 1L)
    stop("Mistura de pipelines de normalizacao; revisar antes da analise.")
  if (!is.numeric(x$abundance) || any(is.infinite(x$abundance)))
    stop("abundance deve ser numerica finita ou NA.")
  if (x$scale[1L] == "raw_positive" && any(x$abundance <= 0, na.rm = TRUE))
    stop("Zero/negativo nao pode receber log2. Codifique nao detectados como NA com motivo.")
  if (!is.numeric(x$identification_qvalue) ||
      any(x$identification_qvalue < 0 | x$identification_qvalue > 1, na.rm = TRUE))
    stop("identification_qvalue deve estar entre 0 e 1, ou NA quando indisponivel.")
  if (!is.logical(x$qc_pass) || anyNA(x$qc_pass)) stop("qc_pass deve ser TRUE ou FALSE.")
  if (any(is.na(x$abundance) & (is.na(x$missing_reason) | !nzchar(x$missing_reason))))
    stop("Cada abundancia ausente precisa de missing_reason.")
  keys <- x[c("sample_id", "analyte_id", "technical_replicate")]
  if (anyDuplicated(keys)) stop("Duplicacao de amostra/analito/replicata tecnica.")
  groups <- split(x$group, x$participant_id)
  if (any(vapply(groups, function(z) length(unique(z)) != 1L, logical(1))))
    stop("Participante associado a mais de um grupo.")
  samples <- split(seq_len(nrow(x)), x$sample_id)
  stable <- c("participant_id", "group", "visit", "prep_batch", "ms_batch")
  for (ii in samples) {
    if (any(vapply(x[ii, stable, drop = FALSE], function(z) length(unique(z)) != 1L, logical(1))))
      stop("Metadados inconsistentes ou replicatas entre lotes na mesma amostra; requer modelo especifico.")
  }
  mapping <- unique(x[c("participant_id", "visit", "sample_id")])
  if (anyDuplicated(mapping[c("participant_id", "visit")]))
    stop("Mais de uma amostra biologica por participante/visita; defina agregacao explicitamente.")
  invisible(TRUE)
}

read_omics <- function(path) {
  x <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"),
                       check.names = FALSE)
  if (!nrow(x)) stop("Planilha modelo vazia; nao ha dados laboratoriais.")
  for (nm in intersect(c("abundance", "identification_qvalue"), names(x))) {
    if (all(is.na(x[[nm]]))) x[[nm]] <- as.numeric(x[[nm]])
  }
  validate_omics(x)
  x
}

prepare_omics <- function(x) {
  validate_omics(x)
  # A normalizacao deve ter sido definida e aplicada no pipeline laboratorial.
  # Nao imputar, filtrar por efeito ou tratar ausencia como zero automaticamente.
  x$log2_abundance <- if (x$scale[1L] == "log2") x$abundance else log2(x$abundance)
  by_analyte <- split(seq_len(nrow(x)), x$analyte_id)
  qc <- do.call(rbind, lapply(by_analyte, function(ii) {
    z <- x[ii, , drop = FALSE]
    data.frame(analyte_id = z$analyte_id[1L], n_records = nrow(z),
               n_participants = length(unique(z$participant_id)),
               missing_fraction = mean(is.na(z$abundance)),
               failed_qc_fraction = mean(!z$qc_pass),
               n_ms_batches = length(unique(z$ms_batch)), stringsAsFactors = FALSE)
  }))
  x$usable <- x$qc_pass & !is.na(x$log2_abundance)
  chunks <- split(seq_len(nrow(x)), interaction(as.integer(factor(x$sample_id)),
                                               as.integer(factor(x$analyte_id)), drop = TRUE))
  collapsed <- do.call(rbind, lapply(chunks, function(ii) {
    z <- x[ii, , drop = FALSE]
    v <- z$log2_abundance[z$usable]
    meta <- z[1L, c("participant_id", "group", "visit", "assay", "sample_id", "analyte_id",
                     "prep_batch", "ms_batch"), drop = FALSE]
    meta$log2_abundance <- if (length(v)) mean(v) else NA_real_
    meta$n_technical_usable <- length(v)
    meta$technical_ss <- if (length(v) > 1L) sum((v - mean(v))^2) else 0
    meta$technical_df <- max(length(v) - 1L, 0L)
    meta
  }))
  rownames(collapsed) <- NULL
  list(abundances = collapsed, quality = qc,
       normalization = unique(x$normalization),
       note = "Media log2 somente de replicatas tecnicas do MESMO analito; nao agrega peptideos em proteinas.")
}

estimate_omics_variance <- function(prepared, post_visit = "T1", min_pairs = 3L,
                                    batch_policy = c("reject", "paired_cancels", "precorrected")) {
  batch_policy <- match.arg(batch_policy)
  if (!post_visit %in% c("T1", "T2")) stop("post_visit deve ser T1 ou T2.")
  if (length(min_pairs) != 1L || min_pairs < 2 || min_pairs != as.integer(min_pairs))
    stop("min_pairs deve ser inteiro >=2.")
  d <- prepared$abundances
  if (is.null(d) || !nrow(d)) stop("Use prepare_omics com dados adequados primeiro.")
  b <- d[d$visit == "T0", , drop = FALSE]
  p <- d[d$visit == post_visit, , drop = FALSE]
  paired <- merge(b, p, by = c("participant_id", "group", "assay", "analyte_id"),
                  suffixes = c("_T0", "_post"), all = TRUE)
  paired$complete <- !is.na(paired$log2_abundance_T0) & !is.na(paired$log2_abundance_post)
  selected <- d[d$visit %in% c("T0", post_visit), , drop = FALSE]
  multi_batch <- length(unique(selected$prep_batch)) > 1L || length(unique(selected$ms_batch)) > 1L
  if (multi_batch && batch_policy == "reject")
    stop("Multiplos lotes: revisar balanceamento; escolher politica explicita, sem ajuste automatico.")
  if (multi_batch && batch_policy == "paired_cancels") {
    cp <- paired[paired$complete, , drop = FALSE]
    if (any(cp$ms_batch_T0 != cp$ms_batch_post | cp$prep_batch_T0 != cp$prep_batch_post))
      stop("paired_cancels requer mesmo lote de preparo e MS nos dois momentos de cada par.")
  }
  if (multi_batch && batch_policy == "precorrected" &&
      !grepl("batch", prepared$normalization, ignore.case = TRUE))
    stop("Documente a correcao validada de lotes em normalization (incluindo 'batch').")
  paired$change <- paired$log2_abundance_post - paired$log2_abundance_T0
  paired$comparison <- paste0(post_visit, "-T0")
  # Variancia tecnica observada e variancia TOTAL da mudanca. Sem replicatas nao
  # ha identificacao separada de componentes biologico e tecnico (Clough p.5).
  all_features <- sort(unique(d$analyte_id))
  summaries <- lapply(all_features, function(id) {
    z <- paired[paired$analyte_id == id & paired$complete, , drop = FALSE]
    ea <- z[z$group == "EA", , drop = FALSE]
    sh <- z[z$group == "sham", , drop = FALSE]
    ns <- c(nrow(ea), nrow(sh))
    valid <- all(ns >= min_pairs)
    ve <- if (ns[1L] >= 2L) stats::var(ea$change) else NA_real_
    vs <- if (ns[2L] >= 2L) stats::var(sh$change) else NA_real_
    pooled <- if (valid) ((ns[1L]-1)*ve + (ns[2L]-1)*vs)/(sum(ns)-2) else NA_real_
    tech <- selected[selected$analyte_id == id, , drop = FALSE]
    tdf <- sum(tech$technical_df)
    tv <- if (tdf > 0) sum(tech$technical_ss)/tdf else NA_real_
    corr <- function(a) {
      if (nrow(a) < 3 || stats::sd(a$log2_abundance_T0) == 0 || stats::sd(a$log2_abundance_post) == 0)
        return(NA_real_)
      stats::cor(a$log2_abundance_T0, a$log2_abundance_post)
    }
    data.frame(assay = d$assay[1L], analyte_id = id, comparison = paste0(post_visit,"-T0"),
      n_pairs_EA = ns[1L], n_pairs_sham = ns[2L],
      var_change_EA = ve, var_change_sham = vs,
      pooled_sd_change = sqrt(pooled), technical_variance = tv, technical_df = tdf,
      rho_EA = corr(ea), rho_sham = corr(sh),
      delta_change_log2 = if (valid) mean(ea$change)-mean(sh$change) else NA_real_,
      usable_for_provisional_planning = valid,
      batch_policy = batch_policy, stringsAsFactors = FALSE)
  })
  list(feature_summary = do.call(rbind, summaries), paired_data = paired,
       quality = prepared$quality,
       limitation = paste("Estimativas exploratorias de pares completos, sem imputacao.",
         "Variancia da mudanca inclui erro tecnico residual; nao descontado automaticamente.",
         "Planejamento futuro exige estabilidade do protocolo, variancia e numero de replicatas.",
         "Ausencias informativas podem enviesar estas estimativas."))
}

omics_two_group_power <- function(n_per_group, delta_log2, sd_change, alpha) {
  if (length(n_per_group) != 1L || !is.finite(n_per_group) || n_per_group < 2 ||
      n_per_group != as.integer(n_per_group)) stop("n_per_group deve ser inteiro >=2.")
  if (length(sd_change) != 1L || !is.finite(sd_change) || sd_change <= 0 ||
      length(delta_log2) != 1L || !is.finite(delta_log2) ||
      length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1)
    stop("DP positivo, delta finito e 0<alpha<1 sao obrigatorios.")
  df <- 2*n_per_group-2
  crit <- stats::qt(1-alpha/2, df)
  ncp <- abs(delta_log2)/sd_change*sqrt(n_per_group/2)
  stats::pt(-crit, df, ncp = ncp) + stats::pt(crit, df, ncp = ncp, lower.tail = FALSE)
}

omics_detectable_effect <- function(n_per_group, sd_change, target_power, q, n_tests) {
  if (length(target_power) != 1L || !is.finite(target_power) || target_power <= 0 || target_power >= 1 ||
      length(q) != 1L || !is.finite(q) || q <= 0 || q >= 1 ||
      length(n_tests) != 1L || !is.finite(n_tests) || n_tests < 1 || n_tests != as.integer(n_tests))
    stop("Escolha explicitamente 0<poder<1, 0<q<1 e numero inteiro positivo de testes.")
  alpha <- q/n_tests
  if (target_power <= alpha) stop("O poder alvo deve exceder o nivel marginal.")
  f <- function(delta) omics_two_group_power(n_per_group, delta, sd_change, alpha)-target_power
  hi <- sd_change
  while (f(hi) < 0) hi <- hi*2
  delta <- stats::uniroot(f, c(0, hi), tol = 1e-9)$root
  data.frame(n_per_group = n_per_group, sd_change_log2 = sd_change,
    target_power = target_power, q_bound = q, n_tests = n_tests,
    marginal_alpha = alpha, detectable_delta_log2 = delta,
    ratio_of_fold_changes = 2^delta,
    method = "Bonferroni: FWER<=q implica FDR<=q; NAO e poder de BH",
    stringsAsFactors = FALSE)
}

omics_sample_size <- function(sd_change, ratio_of_fold_changes, target_power, q,
                             n_tests, loss_fraction, max_n = 100000L) {
  if (length(ratio_of_fold_changes) != 1L || !is.finite(ratio_of_fold_changes) ||
      ratio_of_fold_changes <= 1) stop("Forneca magnitude da razao de fold changes >1.")
  if (length(loss_fraction) != 1L || !is.finite(loss_fraction) || loss_fraction < 0 || loss_fraction >= 1)
    stop("Perda de pares completos deve estar entre 0 e 1.")
  # Valida os parametros de multiplicidade/poder antes da busca.
  omics_detectable_effect(2L, sd_change, target_power, q, n_tests)
  delta <- log2(ratio_of_fold_changes)
  power_at <- function(n) omics_two_group_power(n, delta, sd_change, q/n_tests)
  lo <- 2L; hi <- 2L
  while (hi < max_n && power_at(hi) < target_power) hi <- min(hi*2L, max_n)
  if (power_at(hi) < target_power) stop("Poder nao atingido ate max_n.")
  while (lo < hi) {
    mid <- floor((lo+hi)/2)
    if (power_at(mid) >= target_power) hi <- mid else lo <- mid+1L
  }
  data.frame(n_complete_pairs_per_group = lo,
    n_recruit_per_group = ceiling(lo/(1-loss_fraction)),
    sd_change_log2 = sd_change, ratio_of_fold_changes = ratio_of_fold_changes,
    target_power = target_power, actual_power = power_at(lo), q_bound = q, n_tests = n_tests,
    loss_fraction = loss_fraction,
    method = "Bonferroni: FWER<=q implica FDR<=q; NAO e dimensionamento BH",
    stringsAsFactors = FALSE)
}

omics_adjust_bh <- function(p_values, q, n_family) {
  if (!is.numeric(p_values) || any(p_values < 0 | p_values > 1, na.rm = TRUE))
    stop("p_values devem estar em [0,1].")
  if (length(q) != 1L || !is.finite(q) || q <= 0 || q >= 1 ||
      length(n_family) != 1L || !is.finite(n_family) || n_family < length(p_values) ||
      n_family != as.integer(n_family)) stop("Defina q e tamanho da familia antes da analise.")
  adjusted <- stats::p.adjust(p_values, method = "BH", n = n_family)
  data.frame(p_value = p_values, p_adjusted_BH = adjusted, selected = adjusted <= q)
}
