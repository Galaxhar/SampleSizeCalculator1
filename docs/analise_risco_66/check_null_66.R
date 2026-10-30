# Follow-up to the original n=33 MCAR null result (5.53%; 3.44 Monte Carlo SE).
# Keep that result; investigate with an independent seed and 100,000 replicates.
# Run from repository root. No clinical parameters or original results changed.
source('R/01_parameters.R')
source('R/04_simulation.R')
RNGkind('Mersenne-Twister','Inversion','Rejection')
parameters$nsim <- 100000L
r <- simulate_one_clinical_scenario(parameters, n=33L, delta=0,
 loss_probability=.2, seed=2026103004L)
write.csv(r,'docs/analise_risco_66/null_66_followup.csv',row.names=FALSE)
print(r[c('simulations','rejection_rate','mc_ci_lower','mc_ci_upper','discrepancy_z')])
original <- subset(read.csv('outputs/simulation_mcar.csv'), hypothesis=='nula_erro_tipo_I')
stopifnot(nrow(original)==1, original$n_per_arm_initial==33,
 r$nonestimable_simulations==0, original$seed!=r$seed)
total <- original$simulations+r$simulations
successes <- round(original$simulations*original$rejection_rate+r$simulations*r$rejection_rate)
ci <- simulation_wilson(successes,total)
pooled <- data.frame(simulations=total,rejections=successes,rate=successes/total,
 lower=ci[1],upper=ci[2])
write.csv(pooled,'docs/analise_risco_66/null_66_pooled.csv',row.names=FALSE)
print(pooled)
