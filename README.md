# Cálculo amostral — eletroacupuntura e apneia obstrutiva do sono

Projeto reproduzível em **R**, preparado para consultoria estatística. Os parâmetros
clínicos são hipóteses de planejamento. Leia [o relatório](report.html), sua [fonte Quarto](report.qmd)
ou a [versão Markdown](report.md) e a [auditoria das fontes](docs/source_audit.md).

Revisão de 30/10/2026: [projeto Word com cálculo amostral e randomização em amarelo](docs/projeto_revisado_calculo_randomizacao.docx),
[texto breve de riscos para a cliente](docs/texto_cliente_riscos.docx) e
[fundamentação e referências externas verificadas](docs/fundamentacao_20261030.md).
A meta confirmada é **66 participantes, meta de 33 por braço**, com previsão de
20% de perdas. A randomização usa R e guarda/liberação independente em Excel.
A revisão parcial de 28/10 foi mantida apenas como histórico.

## Executar no RStudio

1. Instale R (verificado com **4.5.0**) e RStudio e extraia a pasta inteira.
2. Abra `SampleSizeCalculator1.Rproj` para definir a raiz do projeto.
3. No console, execute `source("run_all.R")`.

Todos os cálculos, 216 cenários de sensibilidade, simulações e testes usam apenas
pacotes distribuídos com o R (`stats`, `graphics`, `grDevices`, `utils`, `tools`,
`methods` e `base`). **Não é necessário instalar pacotes CRAN.** Não há dados
laboratoriais individuais nos arquivos fornecidos; as planilhas ômicas estão vazias.

No terminal, a partir desta pasta:

```sh
Rscript --vanilla run_all.R
Rscript --vanilla tests/run_tests.R
```

O fluxo executa 20.000 réplicas por cenário: poder e erro tipo I em 24 a 28
avaliáveis/grupo, além de perdas MCAR com 33 recrutados/grupo. As simulações podem
levar alguns minutos. Não reduza esse número para usar os resultados na consultoria.
O CSV registra sementes, contagens efetivas, intervalos Monte Carlo e diagnósticos.

Para apenas refazer tabelas/relatório depois de uma execução completa:

```sh
Rscript --vanilla run_all.R --reuse-simulation
```

Esse modo exige assinatura dos mesmos parâmetros e arquivos de cálculo/simulação;
uma assinatura incompatível interrompe o fluxo. A execução padrão sempre simula.
Os arquivos em `outputs/` são substituídos; arquive resultados anteriores se quiser
comparar versões. Altere premissas exclusivamente em `R/01_parameters.R`.

## Relatório e arquivos

O fluxo gera CSVs, PNGs, PDFs dos gráficos, `report.md`, registros de versões e
resultado dos testes. Se Pandoc estiver no PATH, também gera `report.html`
autocontido, com imagens incorporadas e fórmulas MathML. **Pandoc é opcional**;
foi usado na execução entregue apenas para apresentação, sem cálculos estatísticos.

Alternativamente, após executar R, quem tiver Quarto pode renderizar:

```sh
quarto render report.qmd --to html
```

Não há chunks R no Quarto: ele incorpora os resultados já produzidos pelo fluxo.
O HTML entregue foi renderizado por Pandoc; o comando Quarto é uma alternativa
local, não uma execução verificada neste ambiente.

| Arquivo/pasta | Uso |
|---|---|
| `R/01_parameters.R` | Parâmetros centralizados e números extraídos de Freire |
| `R/02_clinical.R` | ANCOVA, t não central, perdas, tabela de auditoria |
| `R/03_sensitivity.R` | Grade analítica e gráficos |
| `R/04_simulation.R` | Dados simulados, mesmo modelo ANCOVA e MCAR |
| `R/05_omics.R` | Validação, pares, variâncias e planejamento ômico condicionado |
| `R/06_reporting.R` | Tabelas e relatório gerados em R |
| `run_all.R` | Fluxo completo, testes e registro da execução |
| `outputs/clinical_summary.csv` | Resultado clínico central e retenção |
| `outputs/parameter_audit.csv` | Classificação e proveniência de cada premissa |
| `outputs/sensitivity_full.csv` | Os 216 cenários solicitados |
| `outputs/simulation*.csv` | Poder, erro tipo I e incerteza Monte Carlo |
| `outputs/sessionInfo.txt`, `package_versions.csv` | Versões e ambiente executado |
| `data/templates/` | Planilhas ômicas e dicionário dos dados necessários |
| `docs/omics.md`, `docs/simulation.md` | Métodos e limitações dos módulos |
| `references/` | Materiais fornecidos, extrações e SHA256 dos originais |
| `tests/` | Verificações matemáticas e funcionais com exemplos sintéticos |

Os CSVs usam vírgula como separador e ponto decimal, codificação UTF-8. No Excel
em português, importe por **Dados → De Texto/CSV**, selecionando essas opções.
Não interprete o número de linhas de abundâncias como número de participantes.

## Escopo e decisões científicas

O modelo clínico é `IAH_T1 ~ grupo + IAH_T0 + sexo`. Consideram-se duas covariáveis
(sexo binário); gravidade está representada pelo IAH basal contínuo conforme o
protocolo. Não se acrescentaram interações, idade ou IMC.

A simulação verifica o procedimento sob distribuições escolhidas; não valida a
diferença de 6 eventos/h, a correlação 0,5 ou a transportabilidade do DP histórico.
O número calculado é condicionado a essas premissas e à análise de T1.
Não garante o número de avaliáveis nem o poder das análises ômicas ou de T2.

O módulo ômico exige revisão do pipeline, pareamento, lotes e famílias de testes.
Uma comparação de listas de significância dentro de cada grupo não testa a
diferença de mudanças entre grupos. Há funções conservadoras sob Bonferroni
(FWER, que limita FDR), explicitamente distintas de dimensionamento para BH.
Nenhum exemplo sintético é estimativa para este ensaio.

## Ambiente na nuvem

Nesta máquina, R foi instalado localmente em `/workspace/tooling`, com pacote
Debian assinado e checksum verificado. Use:

```sh
/workspace/tooling/bin/Rscript --vanilla run_all.R
```

Para reproduzir essa instalação em **Debian 13 amd64**, com as bibliotecas de
sistema já presentes nesta imagem:

```sh
sh scripts/setup_r_debian.sh
```

O script não instala RStudio nem modifica a instalação de R do computador do
usuário. Para Windows/macOS e outras distribuições, instale R pelo procedimento
normal da plataforma; o projeto estatístico não depende do instalador da nuvem.
