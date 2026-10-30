write_csv_utf8 <- function(x, path) {
  write.csv(x,path,row.names=FALSE,na="",fileEncoding="UTF-8")
}

markdown_table <- function(x, digits = 4L) {
  for (name in names(x)) {
    if (is.numeric(x[[name]])) x[[name]] <- format(round(x[[name]],digits),trim=TRUE,scientific=FALSE)
    x[[name]] <- gsub("|","/",as.character(x[[name]]),fixed=TRUE)
  }
  c(paste0("| ",paste(names(x),collapse=" | ")," |"),
    paste0("| ",paste(rep("---",ncol(x)),collapse=" | ")," |"),
    apply(x,1,function(r) paste0("| ",paste(r,collapse=" | ")," |")))
}

save_simulation_plot <- function(sim, p, path) {
  alt <- sim[sim$hypothesis=="alternativa_poder",]
  alt <- alt[order(alt$n_per_arm_initial),]
  analytical <- vapply(alt$n_per_arm_initial,ancova_power,numeric(1),delta=p$delta,
                       sd=p$sd_post,rho=p$rho,alpha=p$alpha,covariates=p$covariates)
  draw <- function() {
    par(mar=c(4.5,4.5,2.5,1))
    plot(alt$n_per_arm_initial,analytical,type="b",lwd=2,pch=17,col="#df8543",
         ylim=range(c(alt$mc_ci_lower,alt$mc_ci_upper,analytical,p$power)) + c(-.005,.005),
         xlab="Participantes avaliaveis por grupo",ylab="Poder",main="ANCOVA: calculo e simulacao")
    lines(alt$n_per_arm_initial,alt$rejection_rate,type="b",pch=19,col="#1b6b93",lwd=2)
    arrows(alt$n_per_arm_initial,alt$mc_ci_lower,alt$n_per_arm_initial,alt$mc_ci_upper,
           angle=90,code=3,length=.04,col="#1b6b93")
    lines(alt$n_per_arm_initial,alt$conditional_power_mean,lty=3,lwd=2,col="#784c91")
    abline(h=p$power,lty=2,col="gray50")
    legend("bottomright",c("t: covariaveis balanceadas","Simulacao + IC95% Monte Carlo","Media condicional ao desenho"),
           col=c("#df8543","#1b6b93","#784c91"),lty=c(1,1,3),pch=c(17,19,NA),bty="n",cex=.82)
  }
  png(path,width=1150,height=700,res=140);draw();dev.off()
  pdf(sub("png$","pdf",path),width=8,height=5);draw();dev.off()
}

write_report_results <- function(p, clinical, grid, oat, sim, mcar) {
  r <- clinical[1,]
  selected <- sim[sim$n_per_arm_initial==r$n_finite_per_arm & sim$hypothesis=="alternativa_poder",]
  null <- sim[sim$hypothesis=="nula_erro_tipo_I",]
  mcar_alt <- mcar[mcar$hypothesis=="alternativa_poder",]
  discrepancy <- max(abs(sim$discrepancy_z))
  sd_variants <- c(planejamento=p$sd_post,igual_exato=sqrt(mean(freire$sd_post[1:2]^2)),
                  ponderado=sqrt(sum((freire$analyzed[1:2]-1)*freire$sd_post[1:2]^2)/sum(freire$analyzed[1:2]-1)))
  sdt <- data.frame(origem=names(sd_variants),DP=unname(sd_variants))
  sdt$avaliaveis_grupo <- vapply(sdt$DP, function(s) finite_sample_size(p$delta,s,p$rho,p$power,p$alpha,p$covariates),integer(1))
  sdt$recrutar_grupo <- ceiling(sdt$avaliaveis_grupo/(1-p$loss))
  write_csv_utf8(sdt,"outputs/sd_derivations.csv")
  sim_display <- data.frame(n=sim$n_per_arm_initial,
    Hipotese=ifelse(sim$hypothesis=="alternativa_poder","poder","tipo I"),
    Estimativa_pct=100*sim$rejection_rate, EP_MC_pct=100*sim$mc_se,
    IC95_inf_pct=100*sim$mc_ci_lower, IC95_sup_pct=100*sim$mc_ci_upper,
    Condicional_pct=100*sim$conditional_power_mean)
  lines <- c("## Resultados executados em R", "",
    sprintf("Execução: %s. Premissas centrais de planejamento: DP pós %.1f, correlação %.1f, diferença %.1f eventos/h; alfa bilateral %.0f%%, poder %.0f%%, perdas %.0f%%; %d covariáveis.",
      R.version.string,p$sd_post,p$rho,p$delta,100*p$alpha,100*p$power,100*p$loss,p$covariates),"",
    sprintf("**Dimensionamento condicional: %d avaliáveis por grupo; %d recrutados por grupo (%d no total).** A aproximação normal retorna %.4f, arredondada para %d avaliáveis. O cálculo com t e %d graus de liberdade retorna %d, com poder %.2f%% sob balanceamento das covariáveis.",
      r$n_finite_per_arm,r$recruit_per_arm,r$recruit_total,r$n_normal_raw,r$n_normal_per_arm,r$residual_df,r$n_finite_per_arm,100*r$power_at_finite_n),"",
    sprintf("O DP residual usado foi %.6f eventos/h. As alternativas de combinação dos DPs históricos produzem:",r$sd_residual),"",
    markdown_table(sdt),"",
    "Essas alternativas são auditoria da derivação; selecionar o menor DP apenas para reduzir recrutamento não é justificável.","",
    "### Proposta atual e perdas", "",
    sprintf("Recrutar %d/grupo com retenção esperada de %.0f%% produz %.1f avaliáveis/grupo em média. Fixando %d avaliáveis, o poder analítico é %.2f%%; com todos os %d avaliáveis e nenhuma perda, %.2f%%.",
      r$current_recruit_per_arm,100*(1-p$loss),r$expected_evaluable_per_arm,r$fixed_evaluable_for_power,100*r$power_at_expected_floor,r$current_recruit_per_arm,100*r$power_no_losses_current),"",
    sprintf("Na simulação de perdas independentes MCAR, com %d recrutados/grupo, o poder foi %.2f%% (IC95%% Monte Carlo %.2f–%.2f%%). Essa simulação faz análise de casos completos para verificar o método; não implementa a estratégia definitiva de intenção de tratar/imputação.",
      r$current_recruit_per_arm,100*mcar_alt$rejection_rate,100*mcar_alt$mc_ci_lower,100*mcar_alt$mc_ci_upper),"",
    sprintf("Sob retenções binomiais independentes, a probabilidade de ambos os grupos alcançarem pelo menos %d avaliáveis é %.2f%% com %d recrutados/grupo. Dividir pela retenção não garante atingir o alvo; essa probabilidade não é o poder do teste. A meta de %d/grupo também não garante equilíbrio exato ao encerrar blocos estratificados incompletos.",
      r$n_finite_per_arm,100*r$prob_both_reach_n_current,r$current_recruit_per_arm,r$current_recruit_per_arm),"",
    "### Sensibilidade", "",
    sprintf("A grade contém %d cenários, com recrutamento total de %d a %d. Os extremos combinam várias premissas; não são intervalo de confiança. A tabela seguinte altera um parâmetro por vez, mantendo os demais no cenário central.",nrow(grid),min(grid$n_recruit_total),max(grid$n_recruit_total)),"",
    markdown_table(oat),"",
    "### Verificação por simulação", "",
    sprintf("Foram executadas %d réplicas por cenário principal e por cenário MCAR, com sementes registradas em CSV. Todos os cenários principais ajustam o modelo do protocolo com IAH basal e sexo. A distribuição geradora e os estratos estão detalhados em docs/simulation.md.",p$nsim),"",
    markdown_table(sim_display,digits=2L),"",
    sprintf("Em %d avaliáveis/grupo, o poder simulado foi %.2f%% (IC95%% Monte Carlo %.2f–%.2f%%), e a média do poder t condicional às matrizes efetivamente geradas foi %.2f%%. A incerteza de Monte Carlo não mede a incerteza clínica sobre DP, efeito ou correlação.",
      r$n_finite_per_arm,100*selected$rejection_rate,100*selected$mc_ci_lower,100*selected$mc_ci_upper,100*selected$conditional_power_mean),"",
    sprintf("O erro tipo I observado variou de %.2f%% a %.2f%%. A maior discrepância entre rejeição simulada e poder condicional foi %.2f erros-padrão Monte Carlo. O cálculo de covariáveis perfeitamente balanceadas pode ser ligeiramente otimista; o poder condicional usa a matriz real e contabiliza desequilíbrio residual.",100*min(null$rejection_rate),100*max(null$rejection_rate),discrepancy),"",
    "O gerador linear gaussiano pode produzir IAH negativo; a proporção foi registrada por cenário. Não se truncou o desfecho, pois isso mudaria DP, correlação e modelo. É uma verificação matemática da ANCOVA, não um modelo clínico validado da distribuição do IAH.","",
    "### Situação das análises ômicas", "",
    "Não foram fornecidas abundâncias laboratoriais individuais. Nenhum tamanho amostral ômico definitivo foi calculado. O módulo e as planilhas vazias estão preparados para três modalidades separadas. Testes sintéticos de software não constituem estimativas deste projeto.",""
  )
  writeLines(lines,"outputs/report_results.md",useBytes=TRUE)
}

render_report <- function() {
  if (!file.exists("report.qmd")) stop("Fonte report.qmd ausente.")
  lines <- readLines("report.qmd",warn=FALSE,encoding="UTF-8")
  expanded <- unlist(lapply(lines,function(line) {
    if (grepl("{{< include outputs/report_results.md >}}",line,fixed=TRUE))
      readLines("outputs/report_results.md",encoding="UTF-8",warn=FALSE) else line
  }),use.names=FALSE)
  writeLines(expanded,"report.md",useBytes=TRUE)
  pandoc <- Sys.which("pandoc")
  if (nzchar(pandoc)) {
    status <- system2(pandoc,c("report.md","--from=markdown+tex_math_dollars","--to=html5",
      "--standalone","--embed-resources","--mathml","--toc","--metadata","lang=pt-BR",
      "--css=docs/report.css","--output=report.html"))
    if (status!=0L) stop("Falha ao renderizar report.html com Pandoc.")
    writeLines(system2(pandoc,"--version",stdout=TRUE),"outputs/pandoc_version.txt")
  } else message("Pandoc ausente: report.qmd e report.md gerados; HTML opcional via Quarto.")
  invisible(TRUE)
}
