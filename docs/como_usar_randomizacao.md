# Alocação por participante em R

Use o arquivo único [randomizacao.R](../randomizacao.R), com R 4.0 ou posterior. Não requer pacotes adicionais. **Carregar o script não gera nem modifica uma lista.** Os exemplos clínicos reais devem ser executados somente pelo responsável independente; não use identificadores fictícios na pasta do estudo real.

O procedimento gera uma sequência completa uma única vez, antes da primeira inclusão, e libera a próxima posição do estrato a cada solicitação. A razão planejada é 1:1, com blocos permutados de tamanhos variáveis por sexo × gravidade. A meta é 66 participantes; blocos incompletos podem impedir que o total final seja exatamente 33/33. O código não troca as últimas atribuições para preencher cotas.

## 1. Preparação única, antes da primeira inclusão

Baixe `randomizacao.R` e abra-o no RStudio. Execute `source()` com o caminho onde o salvou. Escolha uma pasta privada **local e fora do repositório Git**, sob controle de acesso do pesquisador independente. Exemplo de caminho na sua própria máquina:

```r
source("randomizacao.R", encoding = "UTF-8")
pasta <- file.path(path.expand("~"), "AOS_RANDOMIZACAO_PRIVADA")

# Defina previamente, em registro restrito, os tamanhos pares dos blocos.
# Digite os tamanhos escolhidos separados por virgula quando o R perguntar.
blocos_privados <- scan(
  text = readline("Tamanhos dos blocos previamente definidos: "),
  sep = ",", quiet = TRUE
)
iniciar_randomizacao(pasta, blocos = blocos_privados, total = 66L)
rm(blocos_privados)
```

Escolha pelo menos dois tamanhos pares distintos, de pelo menos quatro participantes. A escolha é uma configuração restrita a ser definida antes do recrutamento, não algo a mudar conforme as pessoas chegam. Tamanhos maiores e variáveis reduzem previsibilidade, mas podem deixar mais desequilíbrio em estratos pequenos. O script não publica uma configuração efetiva de blocos nem uma semente real; as sementes e os tamanhos usados nos testes são apenas exemplos sintéticos.

Por padrão, a semente é criada e arquivada localmente, sem reutilizar o estado de sorteio das simulações públicas do cálculo amostral. O gerador do R não é um mecanismo de criptografia: a proteção da pasta e a separação de funções mantêm o sigilo. A inicialização não deve ser repetida para escolher uma sequência considerada mais conveniente. O código recusa sobrescrever um estudo existente.

Para guardar também a lista fixa no Excel, execute **somente pelo responsável independente**:

```r
exportar_sequencia_restrita(pasta)
```

Esse comando grava `SEQUENCIA_FUTURA_RESTRITA.csv`, contendo as alocações futuras. Importe no Excel por **Dados → De Texto/CSV**, codificação UTF-8 e separador ponto e vírgula; salve como `.xlsx` com **senha para abertura/criptografia**, em local restrito. Não compartilhe a lista, seus blocos ou a semente com a equipe que recruta, trata ou avalia. Não mantenha uma cópia CSV desprotegida em outra pasta. O arquivo exportado pode ser removido depois de sua guarda segura; os arquivos RDS do histórico devem ser preservados.

## 2. A cada solicitação da cliente

Solicite **identificador codificado e estrato**, acompanhados da confirmação de que consentimento, elegibilidade e avaliações basais foram concluídos e registrados. Preserve a solicitação institucional com sua data/hora; o programa registra a data/hora da liberação em UTC. Evite nome, CPF e outros identificadores pessoais no código do participante.

| Estrato a informar | Critério basal |
|---|---|
| `F_LEVE` | Sexo feminino; IAH ≥5 e <15 eventos/h |
| `F_MODERADA` | Sexo feminino; IAH ≥15 e <30 eventos/h |
| `M_LEVE` | Sexo masculino; IAH ≥5 e <15 eventos/h |
| `M_MODERADA` | Sexo masculino; IAH ≥15 e <30 eventos/h |

Essa codificação segue os quatro estratos do planejamento atual. IAH=15 pertence ao estrato moderado; IAH=30 não atende ao critério do estudo. O programa recebe o estrato já conferido; não verifica o exame nem comprova as condições clínicas. Categorias fora dessa codificação exigem definição prévia no protocolo, sem encaixe arbitrário.

Abra o RStudio, carregue o script e informe **sempre a mesma pasta**. O exemplo abaixo pergunta os valores reais no console e não inclui participante de demonstração:

```r
source("randomizacao.R", encoding = "UTF-8")
pasta <- file.path(path.expand("~"), "AOS_RANDOMIZACAO_PRIVADA")

id_recebido <- readline("Identificador recebido: ")
estrato_recebido <- readline("Estrato recebido: ")
operador <- readline("Seu nome ou codigo de responsavel: ")

# TRUE so depois de conferir TCLE, elegibilidade e avaliacoes basais.
recibo <- alocar_participante(
  pasta = pasta,
  identificador = id_recebido,
  estrato = estrato_recebido,
  responsavel = operador,
  confirmacoes = TRUE
)
print(recibo)
```

O recibo apresenta **identificador, estrato, grupo, número da alocação e horário UTC**. Comunique somente a atribuição daquele participante à médica autorizada, conforme o protocolo; não encaminhe o histórico completo. O grupo será `ELETROACUPUNTURA` ou `SHAM`. O registro é confirmado em disco antes de o grupo ser devolvido.

IDs devem ser texto; letras são convertidas para maiúsculas e espaços externos removidos. Assim, `p001` e `P001` identificam a mesma pessoa. IDs repetidos com o mesmo estrato devolvem a alocação existente sem consumir outra posição; repetir com estrato diferente gera erro. O script não identifica se uma mesma pessoa foi cadastrada sob dois códigos distintos: o cadastro de inclusão deve impedir isso.

Para apenas recuperar um recibo:

```r
consultar_alocacao(pasta, identificador = id_recebido)
```

## 3. Registro para Excel e continuidade

Após cada nova alocação, o script atualiza `alocacoes_realizadas.csv` na pasta privada. Esse arquivo contém somente alocações já liberadas, mas ainda revela os grupos e deve ficar restrito. Importe a coluna `identificador` como **texto**, especialmente se houver zeros à esquerda. O horário é registrado explicitamente em UTC.

O controle permanente está nos arquivos RDS numerados da subpasta `estados/`, que contêm a sequência, a configuração e o histórico completo. O CSV é uma exportação para conferência: **editar ou ordenar o Excel não altera a próxima alocação no R**. Não edite, renomeie ou apague arquivos RDS. O script preserva cada versão e interrompe a execução se detectar corrupção, lacunas ou alteração de um registro anterior.

Se o CSV não puder ser escrito, por exemplo porque está aberto no Excel, a alocação **já pode estar confirmada**. O script informa isso e devolve o recibo. Feche o Excel e recupere a exportação:

```r
exportar_alocacoes_excel(pasta)
```

Ao reabrir o R em outro dia, execute apenas `source()` e use a pasta existente. Não inicialize um novo estudo, não use outro ID para contornar um erro e não refaça uma alocação em caso de desistência. Todos os participantes já alocados contam para o limite de 66.

## 4. Guarda e recuperação

- Trabalhe com um responsável central e uma única pasta local ativa; não execute em duas máquinas com cópias independentes ou em diretórios de sincronização simultânea. O bloqueio foi projetado para o sistema de arquivos local, não para um serviço de múltiplos centros.
- CSV e RDS não têm criptografia própria. Proteja **a pasta inteira**, incluindo históricos e cópias de segurança, com permissões e armazenamento criptografado institucional. A senha do Excel protege apenas o `.xlsx`, não os arquivos usados pelo R. `Sys.chmod()` restringe permissões em sistemas que o suportam; no Windows, confira as permissões da pasta.
- Faça cópia segura da pasta completa após cada sessão e preserve as solicitações/recibos separadamente. Não restaure uma cópia anterior e continue alocando sem reconciliar as inclusões posteriores: a exclusão dos últimos arquivos ou a troca pela pasta antiga pode não ser detectável pelo programa.
- Uma pasta `.trava_alocacao` impede operações simultâneas. Normalmente é removida ao terminar. Se o R for encerrado abruptamente, confirme que nenhuma outra sessão está operando, faça uma cópia de segurança e remova **somente essa pasta de trava** antes de conferir o último ID. Nunca remova arquivos em `estados/` para destravar.

Não há função de apagar, reatribuir ou trocar grupos. Erros de cadastro após a alocação exigem registro de desvio e revisão do responsável pelo estudo, preservando o histórico e a atribuição original.

## Verificação e método

Os testes em `tests/test_randomizacao.R` usam apenas participantes fictícios e diretórios temporários. Podem ser executados na raiz do repositório por `Rscript --vanilla tests/test_randomizacao.R`; não inicializam o estudo real.

Na verificação de 30/10/2026, **44 testes passaram em R 4.5.0**, incluindo consulta em outro processo R, idempotência, bloqueio de alteração de estrato, equilíbrio por bloco, limite de 66, falha de gravação antes da confirmação e falha de CSV após a confirmação. O [registro da execução](../outputs/randomizacao_testes.log) acompanha o código. Não houve execução em Windows nesta verificação; o código utiliza funções base do R e grava estados em arquivos novos para evitar a substituição de arquivos abertos.

O método segue a [fundamentação do protocolo](fundamentacao_20261030.md), especialmente Schulz e Grimes (2002) e CONSORT 2025, itens 17–19. A lista real, a semente privada e o procedimento de alocação não se confundem com as sementes públicas das simulações do cálculo amostral.
