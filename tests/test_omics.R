# Fixtures sinteticas APENAS para testar implementacao; nao sao estimativas do projeto.
run_omics_tests <- function() {
  results <- list()
  check <- function(name, assertion) {
    stopifnot(isTRUE(assertion))
    results[[length(results)+1L]] <<- data.frame(test = name, result = "passed")
  }
  fails <- function(expr) inherits(tryCatch(force(expr), error = identity), "error")
  x <- expand.grid(id = seq_len(8), visit = c("T0", "T1"), rep = 1:2,
                   stringsAsFactors = FALSE)
  delta <- rep(c(.1,.2,.4,.5), 2) + c(rep(0,4),rep(1,4))
  d <- data.frame(participant_id = paste0("P",x$id),
    group = ifelse(x$id <= 4,"sham","EA"), visit = x$visit,
    assay = "plasma_proteomics", sample_id = paste0("S",x$id,"_",x$visit),
    analyte_id = "protein_fixture", analyte_level = "protein",
    technical_replicate = as.character(x$rep),
    abundance = 10+x$id+ifelse(x$visit == "T1",delta[x$id],0)+ifelse(x$rep==1,-.1,.1),
    scale = "log2", normalization = "synthetic_fixture", prep_batch = "B1", ms_batch = "B1",
    missing_reason = "", identification_qvalue = NA_real_, qc_pass = TRUE,
    stringsAsFactors = FALSE)
  prepared <- prepare_omics(d)
  csv_path <- tempfile(fileext=".csv")
  on.exit(unlink(csv_path), add=TRUE)
  utils::write.csv(d, csv_path, row.names=FALSE, na="")
  imported <- read_omics(csv_path)
  check("omics_CSV_with_all_missing_identification_qvalues",
        is.numeric(imported$identification_qvalue) && all(is.na(imported$identification_qvalue)))
  est <- estimate_omics_variance(prepared)
  s <- est$feature_summary
  check("omics_preserves_participant_n_with_technical_replicates",
        nrow(prepared$abundances)==16 && s$n_pairs_EA==4 && s$n_pairs_sham==4)
  check("omics_between_group_change_contrast", abs(s$delta_change_log2-1)<1e-12)
  check("omics_technical_variance", abs(s$technical_variance-.02)<1e-12)
  check("omics_change_variance", abs(s$pooled_sd_change-stats::sd(c(.1,.2,.4,.5)))<1e-12)
  z <- d; z$participant_id[1] <- NA_character_
  check("omics_rejects_missing_id", fails(validate_omics(z)))
  check("omics_rejects_duplicate_measurements", fails(validate_omics(rbind(d,d[1,]))))
  z <- d; z$group[1] <- "EA"
  check("omics_rejects_inconsistent_participant_group", fails(validate_omics(z)))
  z <- d; z$abundance[z$participant_id=="P1" & z$visit=="T1"] <- NA_real_
  check("omics_rejects_unexplained_missingness", fails(validate_omics(z)))
  z$missing_reason[is.na(z$abundance)] <- "synthetic_missing"
  missing <- estimate_omics_variance(prepare_omics(z))$feature_summary
  check("omics_missing_pair_reduces_n_without_imputation", missing$n_pairs_sham==3)
  z <- d; z$ms_batch[z$visit=="T1"] <- "B2"
  check("omics_rejects_unsupported_batch_design", fails(estimate_omics_variance(prepare_omics(z))))
  check("omics_rejects_non_cancelling_batch", fails(estimate_omics_variance(prepare_omics(z), batch_policy="paired_cancels")))
  adj <- omics_adjust_bh(c(.001,.02,.5,NA), q=.05, n_family=5)
  check("omics_BH_matches_R_with_declared_family",
        isTRUE(all.equal(adj$p_adjusted_BH,stats::p.adjust(c(.001,.02,.5,NA),"BH",n=5))))
  plan <- omics_sample_size(.5,1.5,.8,.05,100,.2)
  n <- plan$n_complete_pairs_per_group
  check("omics_finite_sample_search_minimal",
    plan$actual_power >= .8 && omics_two_group_power(n-1,log2(1.5),.5,.05/100)<.8)
  check("omics_retention_uses_ceiling_division", plan$n_recruit_per_group==ceiling(n/.8))
  e1 <- omics_detectable_effect(20,.5,.8,.05,1)
  e2 <- omics_detectable_effect(20,.5,.8,.05,100)
  check("omics_multiplicity_increases_detectable_effect", e2$detectable_delta_log2>e1$detectable_delta_log2)
  check("omics_no_definitive_n_without_data", all(is.na(omics_status()$n_definitivo)))
  for (assay in omics_status()$assay) {
    file <- file.path("data","templates",paste0(assay,".csv"))
    template <- utils::read.csv(file, check.names=FALSE)
    check(paste0("omics_empty_template_",assay), nrow(template)==0 && identical(names(template),omics_columns()))
    check(paste0("omics_empty_template_rejected_",assay), fails(read_omics(file)))
  }
  do.call(rbind,results)
}
