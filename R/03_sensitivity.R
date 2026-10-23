calculate_sensitivity <- function(p) {
  grid <- expand.grid(p$grid, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid$alpha <- p$alpha
  grid$covariates <- p$covariates
  grid$sd_residual <- with(grid, sd_post * sqrt(1 - rho^2))
  # Somente 72 combinacoes de eficacia; perdas apenas inflam recrutamento.
  keys <- unique(grid[c("sd_post", "rho", "delta", "power")])
  keys$n_normal_raw <- mapply(normal_sample_size, keys$delta, keys$sd_post,
                              keys$rho, keys$power, MoreArgs = list(alpha=p$alpha))
  keys$n_evaluable_per_arm <- mapply(finite_sample_size, keys$delta, keys$sd_post,
    keys$rho, keys$power, MoreArgs=list(alpha=p$alpha, covariates=p$covariates))
  keyfun <- function(d) do.call(paste, c(d[c("sd_post","rho","delta","power")], sep="|"))
  index <- match(keyfun(grid), keyfun(keys))
  grid$n_normal_raw <- keys$n_normal_raw[index]
  grid$n_normal_per_arm <- ceiling(grid$n_normal_raw)
  grid$n_evaluable_per_arm <- keys$n_evaluable_per_arm[index]
  grid$n_recruit_per_arm <- ceiling(grid$n_evaluable_per_arm / (1-grid$loss))
  grid$n_recruit_total <- 2L * grid$n_recruit_per_arm
  grid$achieved_power <- mapply(ancova_power, grid$n_evaluable_per_arm, grid$delta,
    grid$sd_post, grid$rho, MoreArgs=list(alpha=p$alpha, covariates=p$covariates))
  grid
}

one_at_a_time <- function(p) {
  ans <- list(); i <- 0L
  for (parameter in names(p$grid)) for (value in p$grid[[parameter]]) {
    scenario <- p; scenario[[parameter]] <- value
    result <- clinical_results(scenario)
    i <- i + 1L
    ans[[i]] <- data.frame(parameter=parameter, value=value,
      n_evaluable_per_arm=result$n_finite_per_arm,
      n_recruit_per_arm=result$recruit_per_arm, n_recruit_total=result$recruit_total)
  }
  do.call(rbind, ans)
}

save_sensitivity_plots <- function(grid, oat, p, output_dir) {
  dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
  draw_curves <- function() {
    par(mfrow=c(1,3), mar=c(4.2,4.2,3,1), oma=c(0,0,2,0))
    colors <- c("#1b6b93", "#df8543", "#784c91")
    ymax <- max(subset(grid, power==p$power & loss==p$loss)$n_recruit_total)
    for (sd_value in p$grid$sd_post) {
      plot(NA, xlim=range(p$grid$rho), ylim=c(0,ymax), xlab="Correlacao basal-pos",
           ylab="Participantes a recrutar (total)", main=paste("DP pos =", sd_value))
      for (j in seq_along(p$grid$delta)) {
        d <- subset(grid, sd_post==sd_value & delta==p$grid$delta[j] & power==p$power & loss==p$loss)
        d <- d[order(d$rho),]
        lines(d$rho, d$n_recruit_total, type="b", pch=19, lwd=2, col=colors[j])
      }
      legend("topright", paste("Diferenca =",p$grid$delta), col=colors, pch=19, lty=1, bty="n", cex=.85)
    }
    mtext(sprintf("Cenarios provisorios: poder %.0f%%, perdas %.0f%%, alfa bilateral %.0f%%",100*p$power,100*p$loss,100*p$alpha),outer=TRUE)
  }
  png(file.path(output_dir,"sensitivity_curves.png"),width=1600,height=620,res=140); draw_curves(); dev.off()
  pdf(file.path(output_dir,"sensitivity_curves.pdf"),width=12,height=4.8); draw_curves(); dev.off()
  draw_ranges <- function() {
    ranges <- t(sapply(split(oat$n_recruit_total,oat$parameter),range))
    ranges <- ranges[order(ranges[,2]-ranges[,1]),,drop=FALSE]
    labels <- c(delta="Diferenca (4 a 6)",loss="Perdas (10% a 30%)",power="Poder (80% a 90%)",
                rho="Correlacao (0 a 0.7)",sd_post="DP pos (8.7 a 12)")
    par(mar=c(4,11,3,1))
    plot(NA,xlim=range(ranges)*c(.9,1.1),ylim=c(.5,nrow(ranges)+.5),yaxt="n",
         xlab="Participantes a recrutar (total)",ylab="",main="Um parametro por vez; demais no cenario central")
    axis(2,at=seq_len(nrow(ranges)),labels=labels[rownames(ranges)],las=1)
    for(i in seq_len(nrow(ranges))) {segments(ranges[i,1],i,ranges[i,2],i,lwd=8,col="#1b6b93");points(ranges[i,],c(i,i),pch=19)}
    abline(v=clinical_results(p)$recruit_total,lty=2,col="#df8543")
  }
  png(file.path(output_dir,"sensitivity_ranges.png"),width=1200,height=650,res=140); draw_ranges(); dev.off()
  pdf(file.path(output_dir,"sensitivity_ranges.pdf"),width=9,height=5); draw_ranges(); dev.off()
  invisible(TRUE)
}
