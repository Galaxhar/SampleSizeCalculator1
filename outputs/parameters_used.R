list(sd_post = 8.7, rho = 0.5, delta = 6, alpha = 0.05, power = 0.8, 
    loss = 0.2, recruited_per_arm = 30L, covariates = 2L, model = "iah_week4 ~ group + iah_baseline + sex", 
    seed = 20261022L, nsim = 20000L, simulation_sizes = 24:28, 
    grid = list(sd_post = c(8.7, 10, 12), rho = c(0, 0.3, 0.5, 
    0.7), delta = c(4, 5, 6), power = c(0.8, 0.9), loss = c(0.1, 
    0.2, 0.3)))
