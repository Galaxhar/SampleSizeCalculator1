## Resultados executados em R

Execução: R version 4.5.0 (2025-04-11). Premissas centrais provisórias: DP pós 8.7, correlação 0.5, diferença 6.0 eventos/h; alfa bilateral 5%, poder 80%, perdas 20%; 2 covariáveis.

**Dimensionamento condicional: 26 avaliáveis por grupo; 33 recrutados por grupo (66 no total).** A aproximação normal retorna 24.7534, arredondada para 25 avaliáveis. O cálculo com t e 48 graus de liberdade retorna 26, com poder 80.33% sob balanceamento das covariáveis.

O DP residual usado foi 7.534421 eventos/h. As alternativas de combinação dos DPs históricos produzem:

| origem | DP | avaliaveis_grupo | recrutar_grupo |
| --- | --- | --- | --- |
| planejamento | 8.7000 | 26 | 33 |
| igual_exato | 8.7281 | 26 | 33 |
| ponderado | 8.1985 | 24 | 30 |

Essas alternativas são auditoria da derivação; selecionar o menor DP apenas para reduzir recrutamento não é justificável.

### Proposta atual e perdas

Recrutar 30/grupo com retenção esperada de 80% produz 24.0 avaliáveis/grupo em média. Fixando 24 avaliáveis, o poder analítico é 76.97%; com todos os 30 avaliáveis e nenhuma perda, 85.79%.

Na simulação de perdas independentes MCAR, com 30 recrutados/grupo, o poder foi 76.24% (IC95% Monte Carlo 75.65–76.82%). Essa simulação faz análise de casos completos para verificar o método; não implementa a estratégia definitiva de intenção de tratar/imputação.

Sob retenções binomiais independentes, a probabilidade de ambos os grupos alcançarem pelo menos 26 avaliáveis é 6.51% com 30 recrutados/grupo e 44.31% com 33/grupo. Portanto, dividir pela retenção não garante atingir o alvo. Esses valores não são probabilidades de sucesso do teste.

### Sensibilidade

A grade contém 216 cenários, com recrutamento total de 40 a 546. Os extremos combinam várias premissas; não são intervalo de confiança. A tabela seguinte altera um parâmetro por vez, mantendo os demais no cenário central.

| parameter | value | n_evaluable_per_arm | n_recruit_per_arm | n_recruit_total |
| --- | --- | --- | --- | --- |
| sd_post | 8.7 | 26 | 33 | 66 |
| sd_post | 10.0 | 34 | 43 | 86 |
| sd_post | 12.0 | 49 | 62 | 124 |
| rho | 0.0 | 35 | 44 | 88 |
| rho | 0.3 | 32 | 40 | 80 |
| rho | 0.5 | 26 | 33 | 66 |
| rho | 0.7 | 18 | 23 | 46 |
| delta | 4.0 | 57 | 72 | 144 |
| delta | 5.0 | 37 | 47 | 94 |
| delta | 6.0 | 26 | 33 | 66 |
| power | 0.8 | 26 | 33 | 66 |
| power | 0.9 | 35 | 44 | 88 |
| loss | 0.1 | 26 | 29 | 58 |
| loss | 0.2 | 26 | 33 | 66 |
| loss | 0.3 | 26 | 38 | 76 |

### Verificação por simulação

Foram executadas 20000 réplicas por cenário principal e por cenário MCAR, com sementes registradas em CSV. Todos os cenários principais ajustam o modelo do protocolo com IAH basal e sexo. A distribuição geradora e os estratos estão detalhados em docs/simulation.md.

| n | Hipotese | Estimativa_pct | EP_MC_pct | IC95_inf_pct | IC95_sup_pct | Condicional_pct |
| --- | --- | --- | --- | --- | --- | --- |
| 24 | poder | 76.78 | 0.30 | 76.18 | 77.36 | 76.73 |
| 24 | tipo I | 5.27 | 0.16 | 4.96 | 5.58 | 5.00 |
| 25 | poder | 78.47 | 0.29 | 77.90 | 79.04 | 78.47 |
| 25 | tipo I | 4.84 | 0.15 | 4.56 | 5.15 | 5.00 |
| 26 | poder | 80.44 | 0.28 | 79.88 | 80.98 | 80.11 |
| 26 | tipo I | 4.85 | 0.15 | 4.56 | 5.16 | 5.00 |
| 27 | poder | 81.91 | 0.27 | 81.37 | 82.44 | 81.64 |
| 27 | tipo I | 5.16 | 0.16 | 4.86 | 5.47 | 5.00 |
| 28 | poder | 83.44 | 0.26 | 82.91 | 83.94 | 83.07 |
| 28 | tipo I | 4.93 | 0.15 | 4.64 | 5.24 | 5.00 |

Em 26 avaliáveis/grupo, o poder simulado foi 80.44% (IC95% Monte Carlo 79.88–80.98%), e a média do poder t condicional às matrizes efetivamente geradas foi 80.11%. A incerteza de Monte Carlo não mede a incerteza clínica sobre DP, efeito ou correlação.

O erro tipo I observado variou de 4.84% a 5.27%. A maior discrepância entre rejeição simulada e poder condicional foi 1.72 erros-padrão Monte Carlo. O cálculo de covariáveis perfeitamente balanceadas pode ser ligeiramente otimista; o poder condicional usa a matriz real e contabiliza desequilíbrio residual.

O gerador linear gaussiano pode produzir IAH negativo; a proporção foi registrada por cenário. Não se truncou o desfecho, pois isso mudaria DP, correlação e modelo. É uma verificação matemática da ANCOVA, não um modelo clínico validado da distribuição do IAH.

### Situação das análises ômicas

Não foram fornecidas abundâncias laboratoriais individuais. Nenhum tamanho amostral ômico definitivo foi calculado. O módulo e as planilhas vazias estão preparados para três modalidades separadas. Testes sintéticos de software não constituem estimativas deste projeto.

