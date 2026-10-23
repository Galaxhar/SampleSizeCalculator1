# Executar da raiz: Rscript --vanilla run_all.R
# No RStudio: abrir SampleSizeCalculator1.Rproj e source("run_all.R").
if (!file.exists("R/01_parameters.R")) stop("Execute da raiz do projeto (abra o arquivo .Rproj).")
options(stringsAsFactors=FALSE, warn=1)
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
for (file in c("01_parameters.R","02_clinical.R","03_sensitivity.R",
               "04_simulation.R","05_omics.R","06_reporting.R")) source(file.path("R",file))
dir.create("outputs/figures",recursive=TRUE,showWarnings=FALSE)
started <- Sys.time()
clinical <- clinical_results(parameters)
sensitivity <- calculate_sensitivity(parameters)
oat <- one_at_a_time(parameters)
write_csv_utf8(clinical,"outputs/clinical_summary.csv")
write_csv_utf8(freire,"outputs/freire_extracted.csv")
write_csv_utf8(audit_parameters(parameters,freire),"outputs/parameter_audit.csv")
write_csv_utf8(sensitivity,"outputs/sensitivity_full.csv")
write_csv_utf8(oat,"outputs/sensitivity_one_at_a_time.csv")
write_csv_utf8(omics_status(),"outputs/omics_status.csv")
dput(parameters,file="outputs/parameters_used.R")
save_sensitivity_plots(sensitivity,oat,parameters,"outputs/figures")

signature <- list(parameters=parameters,
  code_md5=tools::md5sum(c("R/01_parameters.R","R/02_clinical.R","R/04_simulation.R")))
reuse <- "--reuse-simulation" %in% commandArgs(trailingOnly=TRUE)
if (reuse) {
  if (!all(file.exists(c("outputs/simulation.csv","outputs/simulation_mcar.csv","outputs/simulation_signature.rds"))) ||
      !identical(signature,readRDS("outputs/simulation_signature.rds")))
    stop("Cache de simulacao ausente ou incompativel. Execute sem --reuse-simulation.")
  simulation <- read.csv("outputs/simulation.csv")
  mcar <- read.csv("outputs/simulation_mcar.csv")
  message("Reutilizando simulacoes executadas com os mesmos parametros e codigo (MD5 conferido).")
} else {
  simulation <- simulate_clinical(parameters,sort(unique(c(parameters$simulation_sizes,clinical$n_finite_per_arm))))
  mcar <- simulate_recruitment_mcar(parameters,parameters$recruited_per_arm)
  write_csv_utf8(simulation,"outputs/simulation.csv")
  write_csv_utf8(mcar,"outputs/simulation_mcar.csv")
  saveRDS(signature,"outputs/simulation_signature.rds")
  capture.output(sessionInfo(),file="outputs/simulation_sessionInfo.txt")
  writeLines(paste("RNG:",paste(RNGkind(),collapse=", ")),"outputs/simulation_rng.txt")
}
if (any(simulation$nonestimable_simulations>0) || any(mcar$nonestimable_simulations>0))
  stop("Simulacoes com modelo nao estimavel: investigar antes de emitir relatorio.")
if (any(abs(simulation$discrepancy_z)>4))
  warning("Discrepancia Monte Carlo acima de 4 EP: investigar outputs/simulation.csv.")
save_simulation_plot(simulation,parameters,"outputs/figures/simulation_power.png")
write_report_results(parameters,clinical,sensitivity,oat,simulation,mcar)
source("tests/run_tests.R")
capture.output(sessionInfo(),file="outputs/sessionInfo.txt")
packages <- installed.packages()
write_csv_utf8(as.data.frame(packages[,c("Package","Version","Priority")]),"outputs/package_versions.csv")
writeLines(c(paste("Inicio UTC:",format(started,tz="UTC",usetz=TRUE)),
             paste("Fim UTC:",format(Sys.time(),tz="UTC",usetz=TRUE)),
             paste("Simulacoes reutilizadas:",reuse),
             "Calculos e simulacoes realizados exclusivamente em R."),"outputs/execution_log.txt")
render_report()
message("Concluido. Leia report.html ou report.md; tabelas e graficos em outputs/.")
