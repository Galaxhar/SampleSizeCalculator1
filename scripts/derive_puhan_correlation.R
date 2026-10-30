# Puhan2006, BMJ332:266-270, Tabelas1/2; PMID16377643, PMC1360393.
# Coeficientes DERIVADOS de resumos arredondados, nao reportados pelos autores.
# Executar da raiz do projeto; os mesmos 25 participantes completaram o estudo.
d <- data.frame(group=c("didgeridoo","lista_espera"), n=c(14,11),
                sd_baseline=c(5.0,4.7),sd_final=c(8.1,9.8),sd_change=c(7.7,6.9))
d$covariance <- with(d,(sd_baseline^2+sd_final^2-sd_change^2)/2)
d$rho_derived <- with(d,covariance/(sd_baseline*sd_final))
rho_within <- with(d,sum((n-1)*covariance)/
                    sqrt(sum((n-1)*sd_baseline^2)*sum((n-1)*sd_final^2)))
stopifnot(all(abs(d$rho_derived)<1),abs(rho_within-0.5590108)<1e-6)
print(d)
print(data.frame(rho_pooled_within_arms=rho_within))
write.csv(d,'outputs/puhan_derived_correlations.csv',row.names=FALSE)
write.csv(data.frame(rho_pooled_within_arms=rho_within),
          'outputs/puhan_pooled_correlation.csv',row.names=FALSE)
