# Revisão parcial do protocolo — 28/10/2026

**O arquivo `projeto_randomizacao_revisao_parcial.docx` é uma revisão parcial para discussão, não uma versão final para submissão ao CEP.** Substitui a descrição anterior de randomização por uma seção após o delineamento e antes de “População do estudo”. O título, os dois parágrafos e as duas referências acrescentadas estão destacados em amarelo. O original está preservado.

O cálculo amostral do DOCX original ainda precisa ser substituído: suas menções a 60 participantes não incorporam a correção já demonstrada no projeto R. No cenário com DP 8,7, correlação 0,5, diferença de 6 eventos/h, alfa bilateral 5%, poder 80% e perdas 20%, o cálculo R indica 26 avaliáveis e meta de 33 recrutados por braço, 66 no total. A correlação permanece uma hipótese e sua fundamentação bibliográfica está pendente. Não alterar esse parâmetro silenciosamente nem apresentar 66 como resultado independente dessa hipótese.

## O que a evidência disponível permite afirmar

Freire AO et al. *Treatment of moderate obstructive sleep apnea syndrome with acupuncture: a randomised, placebo-controlled pilot trial*. Sleep Med. 2007;8:43–50. DOI: https://doi.org/10.1016/j.sleep.2006.04.009. O PDF fornecido pelo usuário foi efetivamente inspecionado.

| Parâmetro | Fundamentação e limite |
|---|---|
| DP final 8,7 eventos/h | Derivado da Tabela 3: raiz de [(5,6² + 11,0²)/2] = 8,728, arredondado para 8,7. É uma combinação das variâncias com pesos iguais; o DP agrupado ponderado por n−1 seria 8,199. O pequeno piloto não estabelece variância comum nem garante transporte ao novo ensaio. |
| Correlação 0,5 | O artigo não informa esse coeficiente, nem o DP da mudança que permitiria recuperá-lo da tabela. Trata-se da hipótese atual de planejamento. |
| Diferença de 6 eventos/h | Estimativa clínica da diferença entre os grupos em T1, ajustada pelo basal; não é redução percentual nem diferença mínima clinicamente importante validada pelo artigo. Precisa de justificativa clínica explícita. |
| Poder 80% e alfa bilateral 5% | Escolhas de desenho: controlar o erro tipo I e a probabilidade de detectar a diferença-alvo sob as hipóteses. 80% é poder, não tamanho de efeito. Não são parâmetros biológicos estimados de Freire. |
| Perdas 20% | Previsão operacional a justificar com dados da equipe ou seguimento semelhante. Freire teve 26 concluintes de 36 randomizados: 27,8% de perdas gerais; portanto, esse estudo não confirma uma previsão de apenas 20%. |

## Correlação reconstruída da Figura 3: evidência exploratória

A Figura 3 (p. 48) preserva segmentos vetoriais ligando cada IAH basal ao final. Foram recuperados os 26 pares: 10 acupuntura, 7 sham e 9 sem tratamento. Uma auditoria independente confirmou os segmentos, sem inferir pareamentos a partir de pontos separados.

Os [dados extraídos e scripts de reprodução](auditoria_correlacao_figura3/README.md) acompanham esta nota. A etapa é exploratória e separada da rotina principal de cálculo amostral.

| Grupo | n | r derivado da figura | IC95% de Fisher aproximado |
|---|---:|---:|---:|
| Acupuntura | 10 | 0,615 | −0,024 a 0,897 |
| Sham | 7 | 0,361 | −0,538 a 0,876 |
| Sem tratamento | 9 | 0,897 | 0,577 a 0,978 |

Combinando somente acupuntura e sham, após centrar os valores basais e finais pelas médias de cada braço, obtém-se **r ≈ 0,453**. Foram usados valores calibrados em eventos/h, pois os painéis têm escalas distintas. Não se trata de média dos coeficientes nem de correlação bruta que mistura o efeito do tratamento com a associação individual.

**São estimativas calculadas nesta análise a partir do gráfico; os autores não publicaram esses coeficientes.** As médias e DPs reconstruídos divergem parcialmente da Tabela 3 (por exemplo, sham final 24,97/10,38 no gráfico versus 24,6/11,0 na tabela). Os intervalos não incorporam erro gráfico ou seleção dos concluintes. O estudo avaliou acupuntura manual por dez semanas, com polissonografia final na semana 12, AOS moderada e sham perfurativo; o novo ensaio prevê eletroacupuntura, quatro semanas, AOS leve/moderada e sham não perfurativo.

Assim, 0,453 é um achado exploratório e não foi adotado no cálculo. Não sustenta apresentar 0,5 como correlação publicada e validada. Arredondar para 0,5 reduziria a amostra e não seria conservador. Seriam preferíveis dados pareados originais ou um estudo comparável que informe correlação/covariância, ou DP basal, final e da mudança nos mesmos participantes.

## Fundamentação do sigilo e software

As referências metodológicas incluídas são Schulz e Grimes, *Lancet*, 2002: **Allocation concealment in randomised trials: defending against deciphering**, DOI https://doi.org/10.1016/S0140-6736(02)07750-4; e **Generation of allocation sequences in randomised trials: chance, not choice**, DOI https://doi.org/10.1016/S0140-6736(02)07683-3. Fundamentam a separação entre geração da sequência e proteção contra conhecimento antecipado da alocação. Os campos e registros descritos no novo parágrafo são a operacionalização proposta para este estudo, não uma citação literal desses artigos.

A proposta utiliza **R para gerar a sequência** e **um pesquisador independente para guardar e liberar as atribuições**. O recrutador confirma consentimento, elegibilidade e avaliações basais antes da solicitação; somente a médica recebe o grupo do participante já incluído. A sequência futura, a semente e os tamanhos dos blocos permanecem restritos. O registro das operações também precisa ficar separado dos registros acessíveis aos avaliadores cegos. Nenhuma lista real foi gerada nesta revisão.

**REDCap, com o módulo de randomização, é uma opção de sistema eletrônico**, caso a instituição disponha dele. Sua disponibilidade, permissões e fluxo devem ser configurados e testados antes de nomeá-lo como sistema adotado no protocolo. R sozinho não oferece esse serviço. O texto inserido descreve um mecanismo central independente que pode ser executado sem assumir disponibilidade de REDCap. Não foi implementado sistema eletrônico nesta etapa.

## Limitação da busca externa

As tentativas de consultar PubMed, PMC, Europe PMC e documentação REDCap foram recusadas pelo proxy do ambiente com `403 Forbidden`. A busca bibliográfica externa **não foi concluída**; não se pode inferir inexistência de estudos relevantes. As duas referências metodológicas são referências conhecidas, mas sua conferência remota e a consulta dos textos nesta sessão permanecem pendentes. Não foram acrescentados PMIDs sem confirmação nem alegada verificação recente da indexação.

Os domínios necessários foram salvos no rascunho das configurações do ambiente. Salvar um rascunho pela ferramenta não aplica automaticamente a política à máquina. É necessário salvar as alterações pela interface do ambiente e verificar novamente o acesso; a publicação do ambiente é uma etapa distinta.

Após liberar a consulta, restam: identificar evidência mais adequada para a correlação, apresentar o valor e seus limites, resolver a escolha do parâmetro e atualizar todas as menções ao tamanho amostral no DOCX, com destaque amarelo. Os resultados R existentes não foram alterados nesta revisão parcial.
