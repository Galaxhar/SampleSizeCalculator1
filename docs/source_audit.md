# Auditoria clínica das fontes fornecidas

Documento de trabalho para integração ao projeto R. As referências Pxxxx indicam o índice original, começando em zero, dos parágrafos do DOCX. Não são páginas: a paginação do Word varia com o renderizador. A extração integral corrigida está em `protocol_complete.txt`; ela lê nós `w:t` e `m:t` e exclui nós sob `w:del`, pois `python-docx.paragraph.text` omitia parágrafos inteiros e trechos inseridos. A leitura representa o conteúdo com inserções visíveis e deleções excluídas, sem editar o documento original.

## Desenho confirmado e modelo principal

- P0070: ensaio randomizado, grupos paralelos, 1:1; participantes e avaliadores cegos, terapeuta não cega.
- P0071: randomização por pesquisador independente, estratificada por **sexo e gravidade basal**, com blocos permutados de tamanhos variáveis e 1:1 dentro de cada estrato. Gravidade leve: IAH ≥5 e <15; moderada: IAH ≥15 e <30 eventos/h. Os tamanhos dos blocos não são informados.
- P0073 e P0103: eletroacupuntura verdadeira versus sham não perfurativa; 2 sessões/semana durante 4 semanas, 8 sessões.
- P0074/P0121: T0 basal, T1 semana 4 e T2 semana 16 (12 semanas após terminar a intervenção).
- P0083–P0089: adultos 18–65 anos, IAH ≥5 e <30, baixo risco cardiovascular e sem indicação clínica de CPAP imediato; seleção adicional quanto a sonolência, experiência prévia de acupuntura etc. P0093 exclui obesidade IMC ≥30, entre outras comorbidades.
- **P0172, seção 3.10 Análise estatística, define o modelo principal**: `IAH_T1 ~ grupo + IAH_T0 + sexo`. São **duas covariáveis** (IAH basal e sexo; para sexo de dois níveis, um grau de liberdade), além de intercepto e efeito de grupo: 4 coeficientes e gl residuais `N - 4`, se matriz tiver posto completo. O documento não prevê idade, IMC, interações, nem indicador adicional de gravidade no modelo primário. A gravidade será representada pelo IAH basal contínuo; manter essa escolha explícita. Se sexo tiver mais de dois níveis no banco final, recalcular número de parâmetros e rever planejamento.
- P0173: modelo misto de grupo, tempo, interação grupo × tempo e intercepto aleatório de participante para evolução T0/T1/T2, com durabilidade em T2. É análise longitudinal adicional, não substituição automática da ANCOVA principal.
- P0171/P0179: intenção de tratar; descrição dos dados faltantes e motivos; sensibilidade com imputação múltipla quando apropriada e per-protocol. O cálculo com avaliáveis completos é aproximação de planejamento, não define automaticamente análise completa de casos como ITT.

### Divergências importantes do projeto

1. P0167 define primário como diferença entre grupos na **mudança T1−T0**, enquanto P0080/P0172 definem análise do **IAH T1 ajustado por T0**. Para cálculo, seguir a especificação mais explícita de P0172. ANCOVA da mudança ajustada pelo mesmo T0 e sexo produz exatamente o mesmo coeficiente de tratamento, erro-padrão e teste que ANCOVA de T1; comparação **não ajustada** de mudanças não é equivalente. Harmonizar redação do estimando e modelo no protocolo.
2. P0080 menciona ajuste apenas pelo IAH basal no cálculo, mas P0172 exige também sexo. Incluir seu custo em graus de liberdade; não inventar ganho de precisão por sexo. Considerar efeito prognóstico adicional zero como hipótese conservadora documentada.
3. P0080: “25 avaliáveis/grupo, 20% perdas, 30 randomizados/grupo” é aritmeticamente inconsistente. `ceiling(25 / 0.8) = 32`; 30 × 0.8 = 24 avaliáveis esperados. Aumento simples em 20% (25×1.2=30) não compensa uma perda de 20% dos recrutados. Mesmo divisão correta só garante expectativa, não probabilidade elevada de alcançar o alvo.
4. P0174 prevê testar mudanças pareadas separadamente em cada grupo e confrontar listas ômicas. Isso **não testa** formalmente diferença entre mudanças. Ser significativo em um grupo e não no outro não demonstra interação/efeito da intervenção. Planejar contraste `(T1−T0)_EA − (T1−T0)_sham`, preservando participante; P0180 também precisa ser harmonizado, pois diz que ômicas não estão incluídas no plano acima.

## Freire et al. 2007: dados que podem ser extraídos

Referência: Freire AO et al. *Treatment of moderate obstructive sleep apnea syndrome with acupuncture: A randomised, placebo-controlled pilot trial*. Sleep Medicine 8 (2007), 43–50. DOI 10.1016/j.sleep.2006.04.009.

**Figura 1, p.45 (página 3 do PDF):** 36 randomizados, 12 em cada um de acupuntura, sham e controle sem tratamento; completaram 10, 7 e 9, respectivamente. O texto dos resultados na p.46 confirma total de 26. Não usar 12 e 12 como números analisados para ponderar a variância pós-tratamento.

**Tabela 3, p.47 (página 5 do PDF), linha Apnoea–hypopnea index, mean (SD):**

| Grupo | n completaram | Basal média (DP) | 12 semanas média (DP) |
|---|---:|---:|---:|
| Acupuntura | 10 | 19,9 (4,1) | 10,1 (5,6) |
| Sham | 7 | 21,6 (5,3) | 24,6 (11,0) |
| Controle sem tratamento | 9 | 20,4 (4,4) | 28,2 (18,0) |

O braço sem tratamento não é o comparador sham do novo estudo, portanto seu DP não entra no cenário central derivado dos dois braços pertinentes.

**Variância com pesos iguais:**

`[(5.6)^2 + (11.0)^2] / 2 = 76.18`, logo DP = `sqrt(76.18) = 8.7281154896` eventos/h, arredondável para 8,7. Isso reconstrói numericamente a premissa, mas é **estimativa derivada**, não um DP combinado reportado pelo artigo. É média igual das variâncias, não média aritmética dos DPs (que seria 8,3). Como alvo de planejamento de dois grupos futuros de mesmo tamanho, representa a média das duas variâncias históricas; não resolve sua desigualdade nem incerteza.

**DP combinado amostral ponderado pelos graus de liberdade:**

`sqrt(((10−1)*5.6^2 + (7−1)*11^2)/(10+7−2)) = sqrt(67.216) = 8.1985364548` eventos/h. Sob hipótese de variância comum, esta é a estimativa usual ponderada pelos n efetivamente analisados. Ela dá peso maior ao grupo com DP menor porque esse grupo teve mais avaliáveis. Nenhuma combinação transforma a homocedasticidade em fato; os DPs 5,6 e 11 são bastante diferentes e têm grande incerteza pelo n reduzido. Manter 8,7 no centro solicitado e incluir a derivação ponderada como contraste de auditoria, sem selecioná-la só por diminuir n.

**Médias e efeitos históricos:**

- Diferença pós acupuntura−sham = 10,1−24,6 = −14,5 eventos/h.
- Mudança acupuntura = 10,1−19,9 = −9,8; sham = 24,6−21,6 = +3,0.
- Diferença não ajustada entre mudanças = −12,8 eventos/h.
- Nenhum desses valores é estimativa ANCOVA ajustada nem diferença mínima clinicamente importante (MCID) validada. O alvo absoluto 6 eventos/h é menor que essas diferenças históricas, mas não existe derivação específica do número 6 ou validação MCID nos materiais fornecidos.

**Correlação:** a Tabela 3 contém médias e DPs marginais, não covariância, correlação ou DP da mudança. Os testes relatados são Wilcoxon pareado/Kruskal–Wallis (seção 3, p.46), portanto não converter p-valores em correlação de Pearson. A Figura 3, p.48, mostra trajetórias individuais graficamente, mas não fornece tabela de pares exatos; digitização produziria uma estimativa aproximada com erro, não foi feita e não justifica tratar 0,5 como estimativa publicada. Há informação insuficiente nos resumos numéricos para identificar rho. Seriam necessários os pares individuais ou DP da mudança/covariância.

**Distinção dos DPs:**

`Var(Y1−Y0) = s1² + s0² − 2 rho s1 s0`. O DP da mudança não é o DP pós nem o residual. Em regressão linear de Y1 por Y0, com homocedasticidade e relação linear adequada, `Var(erro) = sigma_pos² (1−rho²)`; com outras covariáveis, em geral `sigma_pos² (1−R²)` do conjunto de preditores, e rho² só substitui esse R² sob a hipótese explicitada. Para 8,7 e rho=0,5, DP residual planejado = 7,534421013. Não aplicar outra redução se a entrada já for residual. Com sexo incluído, uma hipótese documentável é ganho prognóstico adicional zero, mantendo o custo de gl; simulação deve ser compatível.

**Poder versus respondedores:**

- Seção 3, p.46: cálculo preliminar do estudo piloto menciona poder estatístico de 90%, respostas esperadas 80% no tratado e 20% no placebo, alfa 5%, beta 10%. Os 80% de resposta são probabilidade clínica de resposta, não poder.
- Discussão p.48: autores relatam 60% cumprindo critério de resposta (IAH <10 e redução ≥50%) e outros 20% com redução de 50%; falam em 25/grupo para estudo futuro com **90% poder**, usando argumento distinto. Não citar isso como validação de 25/grupo para ANCOVA atual com poder 80%.
- A mesma discussão fala em DPs “5 e 11 antes e depois”, mas isso não é relato de DP comum 8,7 nem de DP residual; a Tabela 3 identifica inequivocamente os 5,6 e 11 pós nos braços relevantes. Preferir tabela para proveniência e registrar ambiguidade textual.

**Transportabilidade:** estudo piloto de AOS moderada (15–30), três braços, acupuntura **manual**, sham penetrante fora dos acupontos, 1 sessão/semana por 10 semanas; PSG pós 2 semanas depois da última sessão (12 semanas). Novo ensaio inclui leve e moderada, eletroacupuntura por 4 semanas, sham não penetrante nos mesmos pontos e T1 ao final da intervenção. A p.48 afirma ausência de ITT por falta de dados dos desistentes. Assim, médias, DPs, retenção e efeito históricos não podem ser presumidos transportáveis diretamente.

## Tabela de classificação sugerida

| Parâmetro | Valor | Classe | Fonte / derivação / limite |
|---|---|---|---|
| DP pós acupuntura | 5,6 | Dado publicado | Freire Tabela 3 p.47; n=10 Figura 1 p.45 |
| DP pós sham | 11,0 | Dado publicado | Freire Tabela 3 p.47; n=7 Figura 1 p.45 |
| DP médio de variâncias iguais | 8,7281 → 8,7 | Estimativa derivada | sqrt((5,6²+11²)/2); não reportado como tal no artigo |
| DP ponderado observado | 8,1985 | Estimativa derivada | sqrt((9*5,6²+6*11²)/15); hipótese comum, não certeza |
| DP 8,7 transportado para semana 4 | 8,7 | Hipótese de planejamento | Protocolo P0080; população/intervenção/tempo diferentes |
| rho basal–T1 | 0,5 | Hipótese de planejamento | Protocolo P0080; não estimável pelos resumos marginais |
| Delta entre grupos | 6 eventos/h | Hipótese de planejamento; aceitação clínica pendente | P0080 chama relevante; não há MCID específica validada nos materiais |
| Alfa bilateral | 0,05 | Hipótese/decisão de planejamento | P0080 e P0171 |
| Poder | 0,80 | Hipótese/decisão de planejamento | P0080; não confundir respostas de Freire |
| Perdas | 0,20 | Hipótese de planejamento | P0080; não estimativa validada para quatro semanas |
| n avaliáveis/grupo | aproximadamente 25 | Estimativa derivada alegada, a recalcular | P0080; fórmula normal aproximada pode explicar, procedimento finito pode mudar |
| n recrutar/grupo atual | 30 | Decisão operacional do protocolo | P0079/P0080; incompatível com compensar 25 avaliáveis e 20% perdas |
| ANCOVA | IAH_T1 ~ grupo + IAH_T0 + sexo | Especificação do protocolo | P0172, covariáveis q=2 se sexo binário |
| Estratos | sexo × gravidade | Especificação do protocolo | P0071, categorias de gravidade; sem indicador redundante acrescentado à ANCOVA |
| Valores da grade de sensibilidade | especificados pelo usuário | Hipóteses de planejamento | Não são extrações de artigos |

## Pontos para decisão científica/consultoria

Confirmar relevância e plausibilidade de delta=6 (não intitulá-la MCID validada); incerteza de sigma e rho e alternativa de atualização cega/piloto se apropriada; viabilidade de aumentar recrutamento conforme cálculo finito; compatibilidade da escala IAH contínua/normal com população limitada e possível piso após intervenção; tratamento de falta de homocedasticidade se necessário; especificação final de ITT, dados ausentes, eventos intercorrentes e imputação; harmonização mudança/ANCOVA; contraste ômico de mudanças entre grupos e família de testes/FDR; parâmetros de randomização (tamanhos de blocos) não necessários para aproximação principal, mas simulação deve assumir e declarar um desenho explícito.
