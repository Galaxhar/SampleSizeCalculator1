# Testes numericos/metodologicos; executar da raiz do projeto.
source("R/01_parameters.R")
source("R/02_clinical.R")
source("R/03_sensitivity.R")

run_clinical_tests <- function() {
  cases <- list()
  check <- function(name, expression) {
    if (!isTRUE(expression)) stop("FALHOU: ", name)
    cases[[length(cases)+1L]] <<- data.frame(test=name, result="PASS")
  }
  fails <- function(expr) inherits(tryCatch(expr,error=identity),"error")
  r <- clinical_results(parameters)
  check("Variancias publicadas: combinacao igual", abs(sqrt(mean(c(5.6,11)^2))-8.7281154896)<1e-9)
  check("Variancias publicadas: ponderacao n-1", abs(sqrt((9*5.6^2+6*11^2)/15)-8.1985364548)<1e-9)
  check("Inflacao por retencao", inflate_losses(25,.2)==32L && inflate_losses(26,.2)==33L)
  check("DP residual nao pode ser reduzido novamente", fails(residual_sd(7.5,.5,"residual")))
  check("Entrada DP residual equivalente", abs(ancova_power(26,6,8.7,.5)-ancova_power(26,6,residual_sd(8.7,.5),sd_type="residual"))<1e-12)
  reference <- power.t.test(n=26,delta=6,sd=residual_sd(8.7,.5),sig.level=.05,
                             alternative="two.sided",strict=TRUE)$power
  check("Sem covariaveis concorda com power.t.test", abs(ancova_power(26,6,8.7,.5,covariates=0)-reference)<1e-12)
  check("Erro tipo I analitico", abs(ancova_power(26,0,8.7,.5)-.05)<1e-12)
  check("Busca inteira minima", ancova_power(r$n_finite_per_arm,6,8.7,.5)>=.8 && ancova_power(r$n_finite_per_arm-1,6,8.7,.5)<.8)
  check("Entradas invalidas bloqueadas", fails(inflate_losses(25,1)) && fails(residual_sd(8.7,1)) && fails(finite_sample_size(0,8.7,.5)))
  grid <- calculate_sensitivity(parameters)
  check("Grade completa 216 cenarios", nrow(grid)==216L && !anyDuplicated(grid[names(parameters$grid)]))
  check("Poder alvo atingido em toda grade", all(grid$achieved_power>=grid$power))
  check("Retencao esperada suficiente em toda grade", all(grid$n_recruit_per_arm*(1-grid$loss)>=grid$n_evaluable_per_arm-1e-10))
  set.seed(31415)
  dat <- data.frame(group=rep(0:1,each=30),baseline=runif(60,5,30),sex=rep(0:1,30))
  dat$post <- 10-6*dat$group+.4*dat$baseline+rnorm(60,sd=7)
  a <- summary(lm(post~group+baseline+sex,data=dat))$coef["group",]
  b <- summary(lm(I(post-baseline)~group+baseline+sex,data=dat))$coef["group",]
  check("ANCOVA pos equivale a mudanca ajustada", max(abs(a-b))<1e-10)
  do.call(rbind,cases)
}

test_results <- run_clinical_tests()
if (file.exists("tests/test_omics.R")) {
  source("R/05_omics.R")
  source("tests/test_omics.R")
  if (exists("run_omics_tests",mode="function")) {
    omics_tests <- run_omics_tests()
    if (is.data.frame(omics_tests) && all(c("test","result") %in% names(omics_tests)))
      test_results <- rbind(test_results,omics_tests[c("test","result")])
  }
}
dir.create("outputs",showWarnings=FALSE)
write.csv(test_results,"outputs/tests.csv",row.names=FALSE,fileEncoding="UTF-8")
print(test_results,row.names=FALSE)
