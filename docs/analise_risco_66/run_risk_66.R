# Supplementary risk analysis; not part of the original pipeline.
# Uses existing validated functions unchanged. No actual allocation list is generated.
root <- normalizePath('.')
out <- file.path(root,'docs/analise_risco_66')
source(file.path(root, 'R/01_parameters.R'))
source(file.path(root, 'R/02_clinical.R'))
source(file.path(root, 'R/04_simulation.R'))
parameters$recruited_per_arm <- 33L
parameters$nsim <- 20000L
RNGkind(kind='Mersenne-Twister', normal.kind='Inversion', sample.kind='Rejection')
write.csv(clinical_results(parameters), file.path(out,'central_66.csv'), row.names=FALSE)
scenarios <- list(
  central=list(), rho_figure=list(rho=.453200714), rho_045=list(rho=.45),
  rho_030=list(rho=.3), sd_10=list(sd_post=10), delta_5=list(delta=5),
  loss_030=list(loss=.3)
)
analytic <- do.call(rbind, lapply(names(scenarios), function(name) {
  p <- modifyList(parameters, scenarios[[name]])
  r <- clinical_results(p)
  data.frame(scenario=name, sd_post=p$sd_post, rho=p$rho, delta=p$delta, loss=p$loss,
    n_evaluable_per_arm=r$n_finite_per_arm, n_recruit_per_arm=r$recruit_per_arm,
    n_recruit_total=r$recruit_total,
    fixed26_power=ancova_power(26L,p$delta,p$sd_post,p$rho,p$alpha,p$covariates),
    expected_evaluable_per_arm_33=33*(1-p$loss),
    floor_expected_power_33=r$power_at_expected_floor)
}))
write.csv(analytic,file.path(out,'sensitivity_66.csv'),row.names=FALSE)
print(analytic)
losses <- c(.1,.2,.3)
seeds <- c(2026103001L,2026103002L,2026103003L)
results <- vector('list',length(losses))
for(i in seq_along(losses)) {
  message('Starting n=33, loss=',losses[i],', B=',parameters$nsim,', seed=',seeds[i])
  results[[i]] <- simulate_one_clinical_scenario(parameters,n=33L,delta=parameters$delta,
    loss_probability=losses[i],seed=seeds[i])
  write.csv(do.call(rbind,results[seq_len(i)]),file.path(out,'simulation_66.csv'),row.names=FALSE)
  print(results[[i]][c('loss_probability','rejection_rate','mc_ci_lower','mc_ci_upper',
   'conditional_power_mean','discrepancy_z','nonestimable_simulations')])
}
all_results <- do.call(rbind,results)
stopifnot(all(all_results$simulations==20000),all(all_results$nonestimable_simulations==0),
 all(abs(all_results$discrepancy_z)<4))
writeLines(trimws(capture.output(sessionInfo()),which='right'),file.path(out,'sessionInfo.txt'))
writeLines(capture.output(RNGkind()),file.path(out,'rng.txt'))
write.csv(data.frame(file=c('R/01_parameters.R','R/02_clinical.R','R/04_simulation.R'),
  md5=unname(tools::md5sum(file.path(root,c('R/01_parameters.R','R/02_clinical.R','R/04_simulation.R'))))),
  file.path(out,'source_hashes.csv'),row.names=FALSE)
