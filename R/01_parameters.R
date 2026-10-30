# Premissas de planejamento, confirmadas em 30/10/2026; incerteza clinica permanece.
parameters <- list(
  sd_post = 8.7, rho = 0.5, delta = 6, alpha = 0.05,
  power = 0.80, loss = 0.20, recruited_per_arm = 33L,
  covariates = 2L, # IAH basal + sexo binario; intercepto e grupo nao incluidos
  model = "iah_week4 ~ group + iah_baseline + sex",
  seed = 20261022L, nsim = 20000L,
  simulation_sizes = 24:28,
  grid = list(sd_post = c(8.7, 10, 12), rho = c(0, 0.3, 0.5, 0.7),
              delta = c(4, 5, 6), power = c(0.8, 0.9), loss = c(0.1, 0.2, 0.3))
)

# Freire et al. (2007), Tabela 3, p.47; Figura 1, p.45.
freire <- data.frame(
  group = c("acupuntura", "sham", "controle_sem_tratamento"),
  randomized = c(12L, 12L, 12L), analyzed = c(10L, 7L, 9L),
  mean_baseline = c(19.9, 21.6, 20.4), sd_baseline = c(4.1, 5.3, 4.4),
  mean_post = c(10.1, 24.6, 28.2), sd_post = c(5.6, 11.0, 18.0)
)
