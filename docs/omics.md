# Planejamento das três avaliações ômicas

Não foram fornecidas abundâncias individuais de laboratório. Não há estimativa de variância, correlação longitudinal, proporção de moléculas realmente alteradas ou tamanho amostral ômico definitivo para este ensaio. `omics_status()` registra essa ausência para proteômica plasmática, proteômica salivar e peptidômica salivar. O DP e a correlação do IAH não são parâmetros das abundâncias moleculares.

## O que os documentos sustentam

O projeto descreve coleta individual em T0, T1 (semana 4) e T2 (semana 16), proteômica plasmática e salivar após digestão por tripsina e peptidômica de peptídeos endógenos salivares, sem digestão enzimática (seções de preparação/análise, parágrafos P0122–P0142 na extração auditada). Os peptídeos trípticos são *features* usadas para quantificar proteínas; não equivalem aos peptídeos naturais do peptidoma e não são participantes independentes. A regra de pelo menos dois peptídeos únicos e detecção em 60% das amostras está descrita para proteínas em P0134. O denominador da regra de 60%, sua aplicação por grupo/momento e a política para o peptidoma devem ser definidos antes da análise; um filtro global pode remover moléculas presentes apenas em uma condição. O módulo não inventa nem aplica esses filtros automaticamente.

Clough et al. (2012), *Statistical protein quantification and significance analysis in label-free LC-MS experiments with complex designs*, DOI [10.1186/1471-2105-13-S16-S6](https://doi.org/10.1186/1471-2105-13-S16-S6), é uma referência metodológica relevante, mas não um piloto de AOS:

| Local do artigo | Contribuição e limite para este ensaio |
|---|---|
| pp. 1–3 | Modelagem de features de LC-MS para inferência sobre proteínas; exemplos são culturas de câncer de mama e 14 pacientes com osteossarcoma, além de 29 controles. Os 130 runs do segundo estudo não são 130 participantes. |
| pp. 4–5 e Figura 4 | Separação conceitual de variação de condições, features, sujeitos e replicatas técnicas; modelos longitudinais preservam o indivíduo. Sem replicatas técnicas, componentes biológico e técnico ficam confundidos. Para generalizar a novos pacientes, a replicação biológica deve ter escopo populacional. |
| pp. 6–7, etapa 4 e equação 1 | Planejamento requer FDR-alvo, poder médio, magnitude de alteração, proporção de hipóteses nulas/alternativas e variâncias específicas do experimento. A simplificação exibida usa dados balanceados, ausência de picos faltantes e variância representativa. Não basta inserir número de proteínas em uma fórmula clínica. |
| pp. 8–9 | Mecanismos distintos de ausência não admitem uma imputação universal. Identificadores de sujeito permitem reconhecer repetição; a implementação histórica do MSstats usa `lm`/`lmer` e contrastes de parâmetros. Isso não prova que qualquer função atual de dimensionamento suporte automaticamente EA × tempo, lotes e perdas deste ensaio. |
| pp. 10–11, Figura 10 | Ganhos de modelagem conjunta e pareamento dependem da estrutura e da variância do próprio estudo. Os números de réplicas da figura não são recomendações para plasma/saliva de pacientes com AOS. |
| pp. 13–16, Tabela 1 | Requer QC, verificação de normalidade/heterocedasticidade e controle de múltiplos testes. A generalização populacional e o mapeamento correto de features precisam ser preservados. |

A equação 1 expressa alteração na escala modelada; a relação entre FDR, poder e limiar marginal depende da composição de hipóteses. Não se aplicou a equação diretamente porque faltam dados e porque a fórmula mostrada não representa integralmente o contraste randomizado longitudinal pretendido. Os suplementos mencionados por Clough não foram fornecidos; nenhuma versão atual do MSstats foi validada aqui. Não é necessário instalar MSstats para executar o presente projeto.

## Contraste e divergência no protocolo

Para atribuir uma alteração à intervenção, a proposta a levar ao consultor é o contraste direto

\[
\theta_j = E[\log_2 A_{j,T1}-\log_2 A_{j,T0}\mid EA]
          -E[\log_2 A_{j,T1}-\log_2 A_{j,T0}\mid sham].
\]

Cada mudança é calculada no mesmo participante. A unidade independente é o participante, mesmo que existam três visitas, várias injeções e milhares de moléculas. `2^theta` é a razão entre os fatores multiplicativos de mudança dos grupos, não um fold change pré/pós de um único grupo. T2 pode gerar outro contraste; a família de testes deve explicitar a multiplicidade adicional.

P0174 do projeto prevê análises pareadas **dentro de cada grupo** e confronto das listas. Uma molécula significativa em EA e não significativa em sham não demonstra diferença entre os efeitos. P0180 ainda afirma que as análises ômicas estão fora do plano estatístico acima, apesar de P0174 descrevê-las. Esses trechos precisam ser harmonizados. O módulo prepara o contraste entre mudanças solicitado pelo usuário como proposta técnica para revisão; não apresenta essa alteração científica como já aprovada no protocolo. Um modelo conjunto com sujeito e grupo × tempo poderá ser preferível, especialmente com T2 ou dados incompletos; deverá ter seu contraste e sua função de dimensionamento verificados explicitamente.

## Planilhas e pré-processamento necessário

Os três CSVs `data/templates/*proteomics.csv` e `saliva_peptidomics.csv` contêm apenas cabeçalhos: não são dados simulados nem observados. `dictionary.csv` define os campos. Cada linha é um analito, uma amostra individual e uma replicata técnica. Complete também `sample_manifest.csv` para registrar horários, fluxo salivar, processamento, lotes, ordem de injeção e QCs, e `feature_mapping.csv` para documentar identificação e agrupamento. Essas duas planilhas são metadados de auditoria e não são agregadas automaticamente pelo módulo.

Antes do planejamento:

1. Exportar as abundâncias individuais e o mapa de features; revisar proteínas compartilhadas, peptídeos únicos e modificações. QC agrupado monitora o equipamento e não conta como participante.
2. Examinar distribuições, gráficos por grupo/tempo/lote, estabilidade do QC, intensidade e proporção de faltantes. Documentar a normalização e sua versão; não normalizar novamente uma exportação já normalizada.
3. Escolher transformação e política para zeros/limites de detecção. O módulo aceita log2 ou abundâncias estritamente positivas e registra `NA` com motivo; não adiciona pseudocontagens ou imputa por padrão.
4. Confirmar que grupo e tempo não estão confundidos com lote. Injeções técnicas do mesmo analito/amostra podem ser resumidas por média log2 após QC; médias de peptídeos distintos não substituem a quantificação de proteínas.
5. Definir famílias de testes: modalidades separadas ou família conjunta, número de contrastes, FDR-alvo e menor alteração relevante por modalidade. BH por modalidade/contraste não controla automaticamente uma família global que reúna todos os resultados.

No projeto, FDR de 1% (P0134) é critério de **identificação** de proteínas/peptídeos pelo pipeline. A FDR de testes de **abundância diferencial** trata outra coleção de hipóteses e precisa de limiar e família próprios. Não inferir q-values individuais a partir do limiar de identificação. Poder de 80% para o IAH não garante poder de 80% para cada molécula, para a média das moléculas ou para todas as três avaliações ômicas.

## Interface implementada e alcance

```r
source("R/05_omics.R")
omics_status()
# Depois de preencher arquivos com dados reais e revisar QC:
# x <- read_omics("data/pilot/plasma_proteomics.csv")
# prepared <- prepare_omics(x)
# estimates <- estimate_omics_variance(prepared, post_visit = "T1")
# estimates$quality
# estimates$paired_data
# estimates$feature_summary
```

`validate_omics()` verifica esquema, IDs, consistência do grupo, visitas, escala, duplicatas e motivos de ausência. Rejeita misturas de modalidades, múltiplas amostras biológicas por visita sem agregação predefinida e replicatas da mesma amostra distribuídas entre lotes, que exigiriam modelo específico. `prepare_omics()` converte explicitamente para log2 se necessário, exclui medições reprovadas em QC e resume apenas replicatas técnicas do mesmo analito.

`estimate_omics_variance()` preserva pares e devolve número de pares por grupo, variância total da mudança por grupo, DP combinado da mudança ponderado pelos graus de liberdade, correlação basal–pós **dentro** de cada grupo, contraste observado entre mudanças e variância técnica estimada a partir das repetições. A variância técnica é a soma dos quadrados intramostra dividida pelos graus de liberdade intramostra. Sem repetição técnica, retorna `NA`, não zero. A variância de mudança ainda inclui o erro de medição das médias técnicas; não se subtrai automaticamente um componente incerto nem se aplica redução `1-rho²` a esse DP.

O padrão rejeita múltiplos lotes. `batch_policy="paired_cancels"` exige que cada par T0/pós esteja no mesmo lote de preparo e MS e pressupõe efeito aditivo constante que se cancela na mudança; isso não resolve interação lote × tempo ou deriva. `"precorrected"` pressupõe correção externa validada, documentada em `normalization`; o código verifica o registro, não a validade científica dessa correção. Desenhos mais complexos requerem modelo explícito de lotes. As estimativas usam pares completos, sem imputação: ausência informativa pode enviesá-las e deve ser investigada antes de projetar o ensaio.

`omics_detectable_effect(n_per_group, sd_change, target_power, q, n_tests)` e `omics_sample_size(sd_change, ratio_of_fold_changes, target_power, q, n_tests, loss_fraction)` são ferramentas **condicionais** para duas médias de mudanças independentes entre grupos, com variâncias comuns e normalidade aproximada. Usam t não central, `df=2n-2`, `ncp=abs(theta)/sd_change*sqrt(n/2)` e limiar bilateral `alpha=q/n_tests`. O módulo nunca escolhe esses argumentos a partir do IAH. O número a recrutar compensa a perda de **pares utilizáveis**, que pode superar a perda clínica de participantes. O mínimo de três pares por grupo para produzir uma estimativa é uma proteção computacional, não indicação de precisão adequada de um piloto.

Esse limiar é Bonferroni: controla FWER e, portanto, também limita FDR por q sob p-values válidos, mesmo com dependência. É um referencial conservador; **não é dimensionamento de poder de Benjamini–Hochberg**, e pode superestimar a amostra necessária para BH. `omics_adjust_bh()` aplica BH a p-values de contrastes já validados, exigindo declaração da família. BH tem suas condições usuais sobre independência/dependência positiva; dependência arbitrária exige avaliação adicional. Planejamento específico de poder médio sob BH requer proporção de hipóteses verdadeiras, distribuição de efeitos, correlação entre moléculas e simulações ou método apropriado. Nada disso está estimado para este projeto.

Nenhum valor numérico de planejamento ômico é emitido no fluxo principal sem dados. Os testes em `tests/test_omics.R` usam somente fixtures sintéticas, marcadas como testes, para verificar pareamento, contraste, contagem de participantes, variância técnica, dados ausentes, lotes, multiplicidade e arredondamento. Esses testes verificam implementação, não premissas científicas.

## Decisões para a consultoria

- Harmonizar P0174/P0180 e definir o contraste direto entre mudanças, incluindo o papel de T2.
- Obter piloto representativo das três modalidades com abundâncias individuais, exportações e metadados de QC.
- Definir magnitude de alteração, famílias de hipóteses, FDR, poder desejado (médio ou por molécula) e estratégia para variâncias heterogêneas.
- Confirmar normalização, filtros independentes do efeito, replicação técnica, tratamento de ausências e modelo de lotes.
- Validar software e desenho de dimensionamento após essas escolhas, mantendo participantes como unidades independentes.
