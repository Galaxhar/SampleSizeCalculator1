# Simulação clínica: geração, hipóteses e interpretação

O arquivo `R/04_simulation.R` verifica o procedimento estatístico em R, sem
dependências externas. As funções não executam ao carregar o arquivo. O script
principal fornece parâmetros e salva as tabelas resultantes. `simulate_clinical`
executa pelo menos 10.000 réplicas **por combinação de tamanho e hipótese**,
usando sementes derivadas de uma semente central fixa. `simulate_recruitment_mcar`
executa cenários adicionais de recrutamento com perdas aleatórias.

## Desenho gerado

O projeto prevê alocação 1:1 estratificada por sexo e gravidade basal (parágrafo
P0079 do texto extraído), com ANCOVA `IAH_T1 ~ grupo + IAH_T0 + sexo` (P0172).
A gravidade não entra novamente como fator na análise: já está representada
pelo IAH basal contínuo. O modelo tem quatro coeficientes, contando intercepto,
grupo, IAH basal e sexo binário. Não inclui interação nem covariáveis adicionais.

Geram-se quatro estratos: sexo 0/1 × AOS leve `[5,15)` / moderada `[15,30)`.
As proporções-alvo de 20%, 20%, 30% e 30% decorrem exclusivamente de uma
distribuição basal uniforme entre 5 e 30 e sexo com proporções próximas de 50%.
**Essas proporções são convenções de simulação, não dados do projeto ou artigos.**
O método dos maiores restos arredonda os números por estrato para inteiros,
mantendo o total de `n` em cada grupo. Dentro de cada estrato, as observações são
randomizadas em um bloco completo com alocação exatamente equilibrada.

Assim, sexo e categoria de gravidade ficam equilibrados entre grupos, enquanto
os valores contínuos de IAH basal apresentam desequilíbrio aleatório dentro dos
estratos. Trata-se de uma aproximação favorável de randomização em blocos
completos; não reproduz possíveis blocos incompletos, proporções reais de sexo
e gravidade nem a lista de randomização do ensaio. Essa lista não foi fornecida.

Dentro de cada categoria de gravidade, o IAH basal é uniforme no intervalo
correspondente. A média `mu_X` e a variância `v_X` da mistura usam os pesos
arredondados efetivamente gerados, incluindo a variância entre estratos:

```
mu_X = sum(w_k * mu_k)
v_X  = sum(w_k * [var_k + (mu_k - mu_X)^2])
```

O resultado na semana 4 é gerado como:

```
Y = 20 - delta * grupo + beta_X * (X - mu_X) + epsilon
beta_X = rho * sd_post / sqrt(v_X)
epsilon ~ Normal(0, sd_post^2 * (1-rho^2))
```

O coeficiente verdadeiro do sexo é zero. Incluí-lo no ajuste consome graus de
liberdade, mas não se presume um ganho prognóstico adicional sem dados.
O sinal negativo de `delta` representa redução do IAH na eletroacupuntura.
O intercepto 20 é arbitrário para a verificação matemática; não é uma previsão
clínica. O modelo mantém DP populacional marginal `sd_post` e correlação
intragrupo `rho` na mistura geradora. Os erros são independentes, homoscedásticos
e normais, com inclinação basal comum nos dois grupos.

Como o resultado usa erros normais, alguns valores simulados podem ser
negativos. A tabela registra essa frequência. Não se truncam esses resultados,
pois isso alteraria variância, correlação e o modelo linear que se pretende
verificar. Esta é uma simulação do **modelo de trabalho da ANCOVA**, não uma
simulação fisiológica validada do IAH. Distribuições assimétricas, efeito piso,
heteroscedasticidade e não linearidade exigem cenários adicionais após consulta.

## Ajuste e diagnóstico

Cada réplica ajusta efetivamente a matriz de desenho do modelo por `lm.fit`.
O teste bilateral do coeficiente de grupo usa a variância residual estimada e
os graus de liberdade residuais (`2*n - 4` sem perdas). A inversa obtida da
decomposição QR leva em conta o desequilíbrio realmente gerado nas covariáveis.

Além da proporção de rejeições, calcula-se em cada desenho `X` o poder
condicional exato sob o modelo normal:

```
lambda_X = abs(delta) / (sigma_e * sqrt([(X'X)^(-1)]_grupo,grupo))
poder_X  = P(t_df(lambda_X) < -t_crit) + P(t_df(lambda_X) > t_crit)
```

A média desses poderes permite distinguir uma falha de implementação de uma
diferença em relação à aproximação analítica com covariáveis ortogonais.
`discrepancy_z` compara a proporção simulada com essa média usando a incerteza
Monte Carlo de `rejeicao - poder_X`. Diferenças isoladas de até cerca de dois
erros padrão são esperadas; várias comparações também podem produzir valores
maiores por acaso. Investigar padrões sistemáticos, não selecionar apenas
cenários favoráveis.

O erro Monte Carlo da proporção é `sqrt(p_hat*(1-p_hat)/B)`; os intervalos de
95% são de Wilson. Sob a hipótese nula, a proporção de rejeições estima o erro
tipo I, e não poder. As correlações e DPs empíricos acumulam momentos centrados
dentro dos grupos para que a diferença de médias do tratamento não infle o DP.
Pequenas diferenças do alvo são esperadas pelo tamanho finito, arredondamento
dos estratos e estimação dos momentos. Casos não estimáveis são contados;
qualquer caso nos cenários principais interrompe o fluxo para investigação.

Em particular, ao fixar as contagens dos estratos, a variância amostral usual do
IAH basal tem esperança `V_dentro + n/(n-1) * V_entre`, enquanto a variância
populacional da mistura é `V_dentro + V_entre`. Isso explica correlações
empíricas próximas de 0,505 e DPs pós próximos de 8,73 em vez de exatamente
0,500 e 8,70 no cenário central. O desvio não representa aumento do erro
residual: a verificação condicional usa o `sigma_e` efetivamente gerado.

## Perdas e intenção de tratar

O módulo adicional começa com 30 randomizados por grupo e remove cada
resultado da semana 4 independentemente, com probabilidade `params$loss`.
Esse mecanismo é MCAR: não depende de grupo, resultado, IAH basal ou sexo.
Assim, com perdas de 20%, 24 avaliáveis por grupo são uma **esperança**, não
uma garantia; os números reais variam e os grupos podem ficar desequilibrados.

O ajuste nesta verificação usa apenas casos completos. Isso não define nem
valida a estratégia de dados ausentes da análise real por intenção de tratar
(P0171/P0179). Não são simuladas imputação múltipla, perdas MAR/MNAR, mudança
de tratamento ou abandono relacionado à resposta. Esses aspectos precisam de
um plano de análise específico. Réplicas não estimáveis, se ocorrerem sob
perdas, são informadas e contam como não rejeições na taxa sobre todas as
réplicas, pois não produziram evidência para rejeitar a hipótese.

## Interfaces

```r
source("R/04_simulation.R")
sim <- simulate_clinical(params, sample_sizes = c(24, 25, 26, 27))
loss_sim <- simulate_recruitment_mcar(params, recruited_per_arm = 30)
```

Campos necessários de `params`: `sd_post`, `rho`, `delta`, `alpha`, `loss`,
`covariates` (exatamente 2), `seed` e `nsim` (mínimo 10.000).
Os resultados são `data.frame`; o chamador decide os caminhos relativos para
exportação. Não há estimativas de resposta individual nem proporção de
respondedores no procedimento.
