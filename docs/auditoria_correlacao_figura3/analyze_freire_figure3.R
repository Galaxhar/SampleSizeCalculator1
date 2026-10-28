# Correlacoes DERIVADAS da figura, nao reportadas pelo artigo nem dados originais.
# Run from the repository root.
setwd('docs/auditoria_correlacao_figura3')
x<-read.csv('freire2007_figure3_pairs.csv')
results<-do.call(rbind,lapply(split(x,x$group),function(d) {
 test<-cor.test(d$y_baseline,d$y_post,method='pearson')
 data.frame(group=d$group[1],n=nrow(d),r_figure=unname(test$estimate),
 fisher_ci_low=test$conf.int[1],fisher_ci_high=test$conf.int[2],
 baseline_mean=mean(d$ahi_baseline_figure),baseline_sd=sd(d$ahi_baseline_figure),
 post_mean=mean(d$ahi_post_figure),post_sd=sd(d$ahi_post_figure),
 sd_change=sd(d$ahi_post_figure-d$ahi_baseline_figure))
}))
write.csv(results,'freire2007_figure3_derived_correlations.csv',row.names=FALSE)
print(results,row.names=FALSE)
writeLines(trimws(capture.output(sessionInfo()), which='right'), 'figure3_sessionInfo.txt')

# Pooled within-arm correlation: calibrate scales before pooling groups.
d <- subset(x, group %in% c("acupuntura", "sham"))
xc <- d$ahi_baseline_figure - ave(d$ahi_baseline_figure, d$group)
yc <- d$ahi_post_figure - ave(d$ahi_post_figure, d$group)
r_within <- sum(xc * yc) / sqrt(sum(xc^2) * sum(yc^2))
print(data.frame(n = nrow(d), r_within_figure = r_within))
stopifnot(nrow(d) == 17L, abs(r_within - 0.453200714) < 1e-8)
