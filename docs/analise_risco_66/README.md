# Análise suplementar da meta de 66 participantes

Executar da raiz do repositório:

```sh
/workspace/tooling/bin/Rscript --vanilla docs/analise_risco_66/run_risk_66.R
```

O script utiliza as funções do projeto e registra seus hashes; gera a sensibilidade analítica e 20.000 simulações por cenário, com 33 recrutados em cada braço e perdas MCAR de 10%, 20% e 30%. Sementes, resultados e sessão do R acompanham os arquivos. Não gera uma lista real de randomização.

O cenário de 20% desta análise usa uma semente independente da rotina principal: 79,90% de poder aqui versus 80,21% em `outputs/simulation_mcar.csv`, ambos compatíveis com a incerteza Monte Carlo. Não selecionar a estimativa mais favorável; o resultado relevante é poder próximo de 80% sob o modelo de trabalho.

`check_null_66.R` é uma verificação adicional do erro tipo I sob a hipótese nula com 20% de perdas, motivada pela flutuação da primeira execução (5,53% em 20.000 réplicas, 3,44 erros-padrão acima de 5%). Preserva esse resultado e registra uma nova execução com semente independente e 100.000 réplicas; não substitui silenciosamente a semente inicial. Os arquivos `null_66_followup.csv` e `null_66_pooled.csv` contêm a verificação e a combinação das duas execuções.

A verificação independente encontrou 5,001% (IC95% Monte Carlo 4,868–5,138%); o conjunto das 120.000 réplicas encontrou 5,089% (4,966–5,215%), compatível com 5%. Esse resultado apoia que a primeira discrepância foi flutuação Monte Carlo sob o modelo avaliado, sem alterar as premissas ou ocultar a execução inicial.

Limitações: dados gerados por modelo linear normal, que pode produzir IAH negativo; números iniciais iguais, estratos completos, perdas independentes do desfecho/prognóstico e análise por casos completos. Não valida os parâmetros clínicos, o mecanismo real de perdas nem a imputação da análise por intenção de tratar. O procedimento real com blocos estratificados pode terminar com desequilíbrio entre os braços.
