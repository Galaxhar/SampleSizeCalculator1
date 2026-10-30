# Fundamentação do cálculo e da randomização — 30/10/2026

A meta confirmada pela consultoria é **66 participantes, com meta de 33 por grupo**, mantendo a previsão de **20% de perdas**. O projeto revisado está em [projeto_revisado_calculo_randomizacao.docx](projeto_revisado_calculo_randomizacao.docx); o [texto breve para a cliente](texto_cliente_riscos.md) explica os riscos. O original e a revisão parcial anterior são preservados como histórico.

## Pesquisa externa e qualidade da evidência

O acesso externo voltou a funcionar. Foram consultados registros MED/PubMed via Europe PMC e textos completos disponíveis no PMC em 30/10/2026. A busca foi direcionada a IAH basal–pós em ensaios de AOS, acupuntura e métodos de ANCOVA/randomização; não constitui revisão sistemática exaustiva. A indexação foi confirmada pelos PMIDs abaixo; ela não garante qualidade nem transportabilidade das estimativas. O resumo de Silva (2020) foi consultado, mas seu texto integral não pôde ser recuperado nesta pesquisa. Os resumos de Borm e Schulz foram conferidos; a fundamentação operacional detalhada utiliza também o texto completo do CONSORT 2025.

## Parâmetros confirmados e natureza da justificativa

| Escolha | Justificativa | Limite para este ensaio |
|---|---|---|
| ANCOVA do IAH em T1, ajustada por IAH basal e sexo | O ajuste pelo basal melhora a precisão sob as hipóteses do modelo (Vickers e Altman, 2001; Borm et al., 2007). O modelo já constava do protocolo. | Inclinação comum, relação linear, variância residual e ajuste adequado; não se presume ganho adicional por sexo. |
| DP final de 8,7 eventos/h | Freire (2007), Tabela 3: DPs finais de 5,6 e 11,0. Raiz da média das variâncias: √[(5,6²+11,0²)/2] = 8,728, arredondada para 8,7. | Combinação com pesos iguais, não DP originalmente publicado nem DP da mudança. Ponderação por n−1 daria 8,199. Piloto pequeno, acupuntura manual e avaliação em 12 semanas; variâncias dos braços distintas. |
| Correlação de 0,5 | Hipótese de magnitude moderada, com apoio indireto em Puhan (2006): correlação combinada dentro dos braços de aproximadamente 0,559, derivada dos DPs basal, final e da mudança. | Não é correlação publicada como tal; n=25, outro tratamento, AOS moderada e quatro meses. Não valida o valor para eletroacupuntura em quatro semanas. |
| Diferença de 6 eventos/h | Estimativa clínica da redução adicional do IAH no grupo eletroacupuntura versus sham. Wang (2020) encontrou diferença média de −6,18 eventos/h (IC95% −9,58 a −2,78). | A metanálise tem I²=94%, evidência baixa e intervenções/comparadores heterogêneos. Silva (2020), em hipertensos com AOS leve/moderada, não encontrou diferença entre acupuntura e sham. O alvo 6 não é benefício garantido nem MCID validada. |
| Poder de 80% | Escolha de desenho para detectar a diferença-alvo, se as premissas forem verdadeiras. | Permite aproximadamente 20% de resultados não significativos mesmo sob a alternativa planejada; não significa 80% de respondedores. |
| Alfa bilateral de 5% | Escolha prévia de controle do erro tipo I para a comparação primária. | Não é estimativa biológica de um estudo prévio nem probabilidade de a hipótese nula ser verdadeira. |
| Perdas de 20% | Margem operacional escolhida pela equipe; recrutamento = teto(26/0,80). | Freire teve 26/36 concluintes, isto é, 27,8% de perdas. Esse piloto não confirma 20%. É necessário acompanhar retenção e razões das perdas; a expectativa não garante 26 avaliáveis por braço. |

O apoio metodológico ao uso da correlação não é evidência de que ela será exatamente 0,5. O projeto explicita a hipótese e apresenta sensibilidade; não atribui esse número a Borm ou Freire como estimativa publicada.

## Derivação da correlação em Puhan et al. (2006)

O ensaio randomizou 25 adultos com AOS moderada para treinamento com didgeridoo ou lista de espera; todos completaram quatro meses. Houve geração computacional, ocultação central e avaliadores do exame do sono cegos. O estudo é pequeno, sem sham e predominantemente masculino; seu desfecho primário foi sonolência, e o IAH foi um dos demais desfechos. Por isso, sua utilidade aqui é indireta.

Nas Tabelas 1 e 2, com os mesmos participantes no basal e no final:

| Braço | n | DP basal | DP final | DP da mudança | Correlação derivada |
|---|---:|---:|---:|---:|---:|
| Didgeridoo | 14 | 5,0 | 8,1 | 7,7 | 0,386667 |
| Lista de espera | 11 | 4,7 | 9,8 | 6,9 | 0,765523 |

Por braço, `cov = (DP_basal² + DP_final² − DP_mudança²)/2` e `r = cov/(DP_basal × DP_final)`. Combinando covariâncias e variâncias centradas por braço, com pesos n−1, obtém-se `r = Σ[(n−1)cov]/√{Σ[(n−1)DP_basal²] × Σ[(n−1)DP_final²]} = 0,559011`. Não se misturam médias de grupos, nem se faz média simples dos dois coeficientes. O script [derive_puhan_correlation.R](../scripts/derive_puhan_correlation.R) reproduz o cálculo a partir dos números tabulados arredondados.

Escolher 0,5 concede menos ganho de precisão que usar 0,559 diretamente, mas isso não o torna conservador perante toda a incerteza: um dos braços de Puhan tem r≈0,387, e a reconstrução exploratória de Freire deu r≈0,453. Diferenças entre os braços também limitam a hipótese de uma relação/variância residual comum. Não foi identificado, no material consultado, um coeficiente diretamente aplicável e robusto para o novo ensaio.

## Resultado, sensibilidade e risco da meta de 66

Com DP 8,7 e r=0,5, o DP residual é `8,7 × √(1−0,5²) = 7,5344`. A aproximação normal resulta em 24,753 participantes por braço; o cálculo com t não central, duas covariáveis e graus de liberdade `2n−4` resulta em **26 avaliáveis por braço** (poder 80,33% sob balanceamento das covariáveis). A inflação de 20% fornece **teto(26/0,8) = 33 por braço; 66 no total**.

| Alteração isolada, demais parâmetros mantidos | Total de recrutamento para o mesmo alvo |
|---|---:|
| Cenário adotado | 66 |
| Correlação 0,45 | 70 |
| Correlação 0,30 | 80 |
| DP 10 eventos/h | 86 |
| Diferença-alvo 5 eventos/h | 94 |
| Perdas 30% | 76 |

Na análise suplementar com 20.000 simulações por cenário, 33 recrutados em cada braço e perdas independentes do prognóstico/desfecho (MCAR), o poder estimado foi 84,78% com 10% de perdas, 79,90% com 20% e 74,48% com 30%; IC95% Monte Carlo, respectivamente, 84,27–85,27%, 79,33–80,44% e 73,87–75,07%. Resultados, sementes e código estão em [analise_risco_66](analise_risco_66/README.md). A oscilação ao redor de 80% é compatível com a incerteza Monte Carlo; não constitui comprovação de poder clínico exato.

Essa simulação verifica um modelo linear normal de trabalho, com casos completos, números iniciais iguais e estratos completos. Não representa perdas relacionadas à resposta, imputação ou toda a incerteza sobre os parâmetros. A distribuição normal pode produzir IAH negativo, limitação registrada no CSV. Os blocos estratificados reais podem terminar incompletos, de modo que 33/33 é uma meta, não uma obrigação a ser obtida alterando as últimas alocações.

A rotina principal foi atualizada para 33 recrutados por braço e executada novamente, com 36 verificações aprovadas. Uma flutuação do erro tipo I na simulação MCAR inicial (5,53% em 20.000 réplicas) motivou 100.000 réplicas independentes adicionais: 5,001%. Combinadas as execuções, a estimativa foi 5,089% (IC95% Monte Carlo 4,966–5,215%). Ambas as execuções permanecem registradas, sem substituição seletiva de resultados.

Perdas relacionadas ao tratamento/desfecho podem gerar viés além de reduzir poder. A prevenção de perdas e a análise de dados faltantes prevista no protocolo permanecem necessárias. A decisão sobre uma eventual alteração do tamanho amostral deve ser previamente formalizada, preservando cegamento e controle do erro; não deve ser guiada por p-valores parciais.

## Randomização em R e Excel

É viável usar **R para gerar a sequência e Excel para sua guarda e o registro operacional**, desde que o sigilo resulte da separação de funções e dos controles de acesso. O CONSORT 2025, itens 17a/17b, 18 e 19, respalda geração computacional, restrições explicitadas, alocação central e proteção da sequência em relação a quem recruta. Não certifica um arquivo Excel específico.

1. O responsável independente gera e confere a lista uma única vez em R, por sexo e gravidade, na razão 1:1 e com blocos de tamanhos variáveis. Define os tamanhos e registra código, versão e semente em arquivo restrito antes do primeiro recrutamento.
2. A lista é exportada como valores fixos. O responsável a guarda em arquivo Excel com criptografia por senha para abertura e armazenamento institucional de acesso restrito. A proteção de células/abas previne alterações acidentais, mas isoladamente não oferece sigilo. Não usar fórmulas aleatórias que recalculam ao abrir a planilha.
3. Quem recruta confirma e registra consentimento, elegibilidade e avaliações basais; envia somente o identificador e o estrato ao responsável central, por canal institucional registrado.
4. O responsável consome a próxima posição disponível do estrato, registra a operação e comunica somente a atribuição daquele participante à médica. A lista completa e as posições futuras não são compartilhadas com recrutadores, terapeuta ou avaliadores.
5. O registro restrito contém ID, estrato, posição da lista, data/hora da solicitação e da liberação, grupo e responsável. Preservam-se registros das solicitações, versões datadas e cópias de segurança; correções devem ser documentadas sem apagar o histórico. Atribuições não são trocadas nem reutilizadas. Os avaliadores recebem um banco separado, sem sequência ou chave de alocação.

Não foi gerada uma lista real de alocação nem incorporada sua semente ao repositório público. O documento descreve o procedimento a executar; sua implementação operacional deve ser conferida antes de incluir o primeiro participante.

## Referências externas verificadas

1. Freire AO, et al. *Treatment of moderate obstructive sleep apnea syndrome with acupuncture: a randomised, placebo-controlled pilot trial.* Sleep Med. 2007;8:43–50. [PMID 17023212](https://pubmed.ncbi.nlm.nih.gov/17023212/). DOI: 10.1016/j.sleep.2006.04.009. PDF fornecido e registro bibliográfico consultados.
2. Puhan MA, Suarez A, Lo Cascio C, Zahn A, Heitz M, Braendli O. *Didgeridoo playing as alternative treatment for obstructive sleep apnoea syndrome: randomised controlled trial.* BMJ. 2006;332:266–270. [PMID 16377643](https://pubmed.ncbi.nlm.nih.gov/16377643/); [texto completo](https://pmc.ncbi.nlm.nih.gov/articles/PMC1360393/). DOI: 10.1136/bmj.38705.470590.55.
3. Wang L, Xu J, Zhan Y, Pei J. *Acupuncture for Obstructive Sleep Apnea (OSA) in Adults: A Systematic Review and Meta-Analysis.* Biomed Res Int. 2020;2020:6972327. [PMID 32258139](https://pubmed.ncbi.nlm.nih.gov/32258139/); [texto completo](https://pmc.ncbi.nlm.nih.gov/articles/PMC7079261/). DOI: 10.1155/2020/6972327. Seção 3.4.1, Tabela 3 e discussão 4.3.
4. Silva MVFP, et al. *Effects of acupuncture on obstructive sleep apnea severity, blood pressure control and quality of life in patients with hypertension: A randomized controlled trial.* J Sleep Res. 2020;29:e12954. [PMID 31868987](https://pubmed.ncbi.nlm.nih.gov/31868987/). DOI: 10.1111/jsr.12954. Resumo consultado; 44 concluintes, sem diferença pré–pós entre braços.
5. Borm GF, Fransen J, Lemmens WA. *A simple sample size formula for analysis of covariance in randomized clinical trials.* J Clin Epidemiol. 2007;60:1234–1238. [PMID 17998077](https://pubmed.ncbi.nlm.nih.gov/17998077/). DOI: 10.1016/j.jclinepi.2007.02.006. Resumo consultado; fundamenta a redução por 1−r², não um r específico.
6. Vickers AJ, Altman DG. *Statistics notes: Analysing controlled trials with baseline and follow up measurements.* BMJ. 2001;323:1123–1124. [PMID 11701584](https://pubmed.ncbi.nlm.nih.gov/11701584/); [texto completo](https://pmc.ncbi.nlm.nih.gov/articles/PMC1121605/). DOI: 10.1136/bmj.323.7321.1123.
7. Schulz KF, Grimes DA. *Allocation concealment in randomised trials: defending against deciphering.* Lancet. 2002;359:614–618. [PMID 11867132](https://pubmed.ncbi.nlm.nih.gov/11867132/). DOI: 10.1016/S0140-6736(02)07750-4. Resumo consultado.
8. Schulz KF, Grimes DA. *Generation of allocation sequences in randomised trials: chance, not choice.* Lancet. 2002;359:515–519. [PMID 11853818](https://pubmed.ncbi.nlm.nih.gov/11853818/). DOI: 10.1016/S0140-6736(02)07683-3. Resumo consultado.
9. Hopewell S, Chan AW, Collins GS, et al. *CONSORT 2025 explanation and elaboration: updated guideline for reporting randomised trials.* BMJ. 2025;389:e081124. [PMID 40228832](https://pubmed.ncbi.nlm.nih.gov/40228832/); [texto completo](https://pmc.ncbi.nlm.nih.gov/articles/PMC11995452/). DOI: 10.1136/bmj-2024-081124. Itens 17a, 17b, 18 e 19 consultados integralmente.
