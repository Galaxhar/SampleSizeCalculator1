# Alocacao central: eletroacupuntura versus sham, 1:1, sexo x gravidade.
# R >= 4.0, somente pacotes que acompanham o R. source() NAO gera uma lista.
# Operar em UMA pasta privada LOCAL, fora do Git e de pastas compartilhadas.
# Leia docs/como_usar_randomizacao.md antes da primeira inclusao.

.ra_estratos <- c('F_LEVE','F_MODERADA','M_LEVE','M_MODERADA')
.ra_grupos <- c('ELETROACUPUNTURA','SHAM')
.ra_stop <- function(...) stop(..., call.=FALSE)
.ra_utc <- function() format(Sys.time(), '%Y-%m-%dT%H:%M:%OS6Z', tz='UTC')
.ra_id <- function(x) {
  if (!is.character(x) || length(x)!=1L || is.na(x))
    .ra_stop('Identificador deve ser texto, entre aspas; ex.: "P001".')
  x <- toupper(trimws(x))
  if (!grepl('^[A-Z0-9][A-Z0-9_.-]{0,63}$',x))
    .ra_stop('Use ID codificado: letras sem acentos, numeros, ponto, hifen ou sublinhado; ate 64 caracteres.')
  x
}
.ra_estrato <- function(x) {
  if (!is.character(x) || length(x)!=1L || is.na(x)) .ra_stop('Informe um estrato como texto.')
  x <- toupper(trimws(x))
  if (!(x %in% .ra_estratos)) .ra_stop('Estrato invalido. Use: ',paste(.ra_estratos,collapse=', '),'.')
  x
}
.ra_int <- function(x, nome, min=1L, max=.Machine$integer.max) {
  if (!is.numeric(x) || length(x)!=1L || !is.finite(x) ||
      x!=floor(x) || x<min || x>max) .ra_stop(nome,': inteiro fora do intervalo permitido.')
  as.integer(x)
}
.ra_pasta <- function(pasta, criar=FALSE) {
  if (!is.character(pasta) || length(pasta)!=1L || is.na(pasta) || !nzchar(trimws(pasta)))
    .ra_stop('Informe o caminho completo de uma pasta privada local.')
  if (!dir.exists(pasta) && criar && !dir.create(pasta,recursive=TRUE,mode='0700'))
    .ra_stop('Nao foi possivel criar a pasta privada.')
  if (!dir.exists(pasta)) .ra_stop('Pasta inexistente; inicialize uma unica vez antes de alocar.')
  path <- normalizePath(pasta,winslash='/',mustWork=TRUE)
  ancestor <- path
  repeat {
    git <- file.path(ancestor,'.git')
    # Uma pasta .git vazia nao caracteriza repositorio (p.ex., marcadores do ambiente).
    is_repo <- (dir.exists(git) && file.exists(file.path(git,'HEAD'))) ||
      (file.exists(git) && !dir.exists(git))
    if (is_repo)
      .ra_stop('A pasta privada deve ficar FORA de um repositorio Git; escolha outro caminho.')
    parent <- dirname(ancestor)
    if (identical(parent,ancestor)) break
    ancestor <- parent
  }
  path
}
.ra_travar <- function(pasta) {
  lock <- file.path(pasta,'.trava_alocacao')
  if (!dir.create(lock,showWarnings=FALSE,mode='0700'))
    .ra_stop('Pasta em uso ou trava de execucao interrompida. Nao remova a trava com outra sessao ativa; consulte o guia.')
  # O lock existe mesmo se o registro informativo nao puder ser escrito.
  try(writeLines(c(paste('PID',Sys.getpid()),.ra_utc()),file.path(lock,'operacao.txt')),silent=TRUE)
  lock
}
.ra_registro_vazio <- function() data.frame(
  numero_alocacao=integer(),identificador=character(),estrato=character(),
  posicao_estrato=integer(),grupo=character(),alocado_em_utc=character(),
  responsavel=character(),confirmacoes=logical(),stringsAsFactors=FALSE)

.ra_gravar <- function(pasta,estado,numero) {
  dir <- file.path(pasta,'estados')
  target <- file.path(dir,sprintf('estado_%06d.rds',numero))
  if (file.exists(target)) .ra_stop('Estado ja existente: nao sera sobrescrito.')
  temporary <- tempfile('.pendente_',tmpdir=dir,fileext='.rds')
  on.exit(unlink(temporary),add=TRUE)
  saveRDS(estado,temporary,version=3)
  if (!identical(readRDS(temporary),estado)) .ra_stop('Falha de verificacao da gravacao; alocacao nao confirmada.')
  Sys.chmod(temporary,mode='0600')
  # Destino novo, no mesmo volume: preserva os estados anteriores, inclusive no Windows.
  if (!file.rename(temporary,target)) .ra_stop('Falha ao confirmar o estado; consulte o ID antes de repetir.')
  invisible(target)
}
.ra_ler <- function(pasta) {
  dir <- file.path(pasta,'estados')
  files <- sort(list.files(dir,pattern='^estado_.*[.]rds$',full.names=TRUE))
  if (!length(files)) .ra_stop('Estudo nao inicializado; nenhuma alocacao foi realizada.')
  expected <- sprintf('estado_%06d.rds',seq.int(0L,length(files)-1L))
  if (!identical(basename(files),expected)) .ra_stop('Historico incompleto ou nomes inesperados. Interrompa e confira a copia de seguranca.')
  first <- previous <- NULL
  for (i in seq_along(files)) {
    state <- tryCatch(readRDS(files[i]),error=function(e)
      .ra_stop('Estado ilegivel: ',basename(files[i]),'. Nao se recupera automaticamente um estado anterior.'))
    if (!is.list(state) || !identical(names(state),c('config','sequencia','registro')))
      .ra_stop('Formato de estado invalido.')
    if (i==1L) {
      first <- state
      cfg <- state$config
      if (!is.list(cfg) || !identical(cfg$versao_formato,1L) ||
          !identical(cfg$estratos,.ra_estratos) || !identical(cfg$grupos,.ra_grupos))
        .ra_stop('Configuracao nao reconhecida.')
      .ra_int(cfg$total,'Total',min=2L,max=100000L)
      if (!is.data.frame(state$sequencia) || !identical(names(state$sequencia),
          c('estrato','posicao','bloco','tamanho_bloco','grupo')))
        .ra_stop('Sequencia invalida.')
      if (!all(state$sequencia$estrato %in% .ra_estratos) ||
          !all(state$sequencia$grupo %in% .ra_grupos)) .ra_stop('Codigos invalidos na sequencia.')
      for (stratum in .ra_estratos) {
        sq <- state$sequencia[state$sequencia$estrato==stratum,,drop=FALSE]
        if (nrow(sq)<cfg$total || !identical(sq$posicao,seq_len(nrow(sq))))
          .ra_stop('Capacidade ou ordem incorreta no estrato ',stratum,'.')
        blocks <- split(sq,sq$bloco)
        for (block in blocks) {
          size <- unique(block$tamanho_bloco)
          if (length(size)!=1L || !(size %in% cfg$blocos) || nrow(block)!=size ||
              sum(block$grupo==.ra_grupos[1])!=size/2)
            .ra_stop('Bloco invalido no plano inicial.')
        }
      }
    } else if (!identical(state$config,first$config) || !identical(state$sequencia,first$sequencia)) {
      .ra_stop('Plano inicial foi alterado entre estados; interrompa a operacao.')
    }
    reg <- state$registro
    if (!is.data.frame(reg) || !identical(names(reg),names(.ra_registro_vazio())) ||
        nrow(reg)!=i-1L || nrow(reg)>state$config$total ||
        !identical(reg$numero_alocacao,seq_len(nrow(reg))) || anyNA(reg) ||
        anyDuplicated(reg$identificador) || !all(reg$confirmacoes))
      .ra_stop('Registro de alocacoes inconsistente.')
    if (i>1L && !identical(reg[seq_len(nrow(previous$registro)),,drop=FALSE],previous$registro))
      .ra_stop('Uma alocacao anterior foi alterada; interrompa a operacao.')
    for (stratum in .ra_estratos) {
      rr <- reg[reg$estrato==stratum,,drop=FALSE]
      sq <- state$sequencia[state$sequencia$estrato==stratum,,drop=FALSE]
      if (!identical(rr$posicao_estrato,seq_len(nrow(rr))) ||
          !identical(rr$grupo,sq$grupo[seq_len(nrow(rr))]))
        .ra_stop('Registro nao corresponde a ordem da sequencia.')
    }
    if (!all(reg$estrato %in% .ra_estratos)) .ra_stop('Estrato invalido no registro.')
    previous <- state
  }
  previous
}
.ra_recibo <- function(row) {
  out <- row[,c('identificador','estrato','grupo','numero_alocacao','alocado_em_utc'),drop=FALSE]
  rownames(out) <- NULL
  out
}
.ra_csv <- function(pasta,reg) {
  # Exportacao derivada: editar o CSV no Excel nunca muda as alocacoes no R.
  target <- file.path(pasta,'alocacoes_realizadas.csv')
  write.csv2(reg,target,row.names=FALSE,fileEncoding='UTF-8')
  Sys.chmod(target,mode='0600')
  target
}

# Execute UMA VEZ, antes do primeiro participante. Nao use semente de exemplos.
# 'blocos' deve conter >=2 tamanhos PARES distintos, previamente definidos em privado.
iniciar_randomizacao <- function(pasta,blocos,total=66L,semente=NULL) {
  total <- .ra_int(total,'Total',min=2L,max=100000L)
  if (!is.numeric(blocos) || length(blocos)<2L || anyNA(blocos) ||
      any(!is.finite(blocos)) || any(blocos!=floor(blocos)) ||
      any(blocos<4 | blocos>100 | blocos%%2!=0) || anyDuplicated(blocos))
    .ra_stop('Defina ao menos dois tamanhos pares distintos de bloco, entre 4 e 100, antes do recrutamento.')
  blocos <- sort(as.integer(blocos))
  if (!is.null(semente)) semente <- .ra_int(semente,'Semente',min=0L)
  pasta <- .ra_pasta(pasta,criar=TRUE)
  lock <- .ra_travar(pasta)
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  estados <- file.path(pasta,'estados')
  if (dir.exists(estados) && length(list.files(estados,all.files=TRUE,no..=TRUE)))
    .ra_stop('Esta pasta ja tem um estudo ou uma inicializacao interrompida. Nao regenere a lista.')
  if (!dir.exists(estados) && !dir.create(estados,mode='0700')) .ra_stop('Nao foi possivel criar o historico.')
  old_kind <- RNGkind()
  had_seed <- exists('.Random.seed',envir=.GlobalEnv,inherits=FALSE)
  old_seed <- if (had_seed) get('.Random.seed',envir=.GlobalEnv) else NULL
  on.exit({
    do.call(RNGkind,as.list(old_kind))
    if (had_seed) assign('.Random.seed',old_seed,envir=.GlobalEnv)
    else if (exists('.Random.seed',envir=.GlobalEnv,inherits=FALSE)) rm('.Random.seed',envir=.GlobalEnv)
  },add=TRUE)
  RNGkind('Mersenne-Twister','Inversion','Rejection')
  if (is.null(semente)) {
    set.seed(NULL) # Reinicializa; nao reutiliza o RNG de simulacoes publicas.
    semente <- sample.int(.Machine$integer.max,1L)
  }
  set.seed(semente)
  sequence <- do.call(rbind,lapply(.ra_estratos,function(stratum) {
    pieces <- list(); n <- 0L; k <- 0L
    while (n<total) {
      size <- blocos[sample.int(length(blocos),1L)]
      k <- k+1L
      group <- sample(rep(.ra_grupos,each=size/2),size=size,replace=FALSE)
      pieces[[k]] <- data.frame(estrato=stratum,posicao=n+seq_len(size),
        bloco=k,tamanho_bloco=size,grupo=group,stringsAsFactors=FALSE)
      n <- n+size
    }
    do.call(rbind,pieces)
  }))
  rownames(sequence) <- NULL
  config <- list(versao_formato=1L,criado_em_utc=.ra_utc(),total=total,
    estratos=.ra_estratos,grupos=.ra_grupos,blocos=blocos,semente=semente,
    R=R.version.string,RNG=RNGkind())
  state <- list(config=config,sequencia=sequence,registro=.ra_registro_vazio())
  .ra_gravar(pasta,state,0L)
  .ra_ler(pasta)
  message('Inicializacao concluida. Lista privada preservada; nenhuma pessoa alocada.')
  invisible(list(pasta=pasta,total=total,estratos=.ra_estratos))
}

# confirmacoes=TRUE atesta TCLE, elegibilidade e avaliacoes basais ja registrados.
# A mesma identificacao normalizada nunca recebe um segundo sorteio.
alocar_participante <- function(pasta,identificador,estrato,responsavel,confirmacoes=FALSE) {
  id <- .ra_id(identificador)
  stratum <- .ra_estrato(estrato)
  if (!is.character(responsavel) || length(responsavel)!=1L || is.na(responsavel) ||
      !nzchar(trimws(responsavel)) || grepl('[\r\n\t]',responsavel) ||
      grepl('^[=+@-]',trimws(responsavel))) .ra_stop('Informe o nome/codigo do responsavel, sem formulas ou quebras de linha.')
  pasta <- .ra_pasta(pasta)
  lock <- .ra_travar(pasta)
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  state <- .ra_ler(pasta)
  reg <- state$registro
  previous <- match(id,reg$identificador)
  if (!is.na(previous)) {
    if (reg$estrato[previous]!=stratum) .ra_stop('ID ja alocado em outro estrato. Nao e permitido realocar; confira a solicitacao.')
    message('ID ja registrado: devolvendo a mesma alocacao, sem consumir outra posicao.')
    return(.ra_recibo(reg[previous,,drop=FALSE]))
  }
  if (!identical(confirmacoes,TRUE))
    .ra_stop('Antes de alocar, confirme TCLE, elegibilidade e avaliacoes basais registradas; entao use confirmacoes=TRUE.')
  if (nrow(reg)>=state$config$total) .ra_stop('Meta total de recrutamento atingida; nenhuma nova alocacao permitida.')
  pos <- as.integer(sum(reg$estrato==stratum)+1L)
  row <- state$sequencia[state$sequencia$estrato==stratum & state$sequencia$posicao==pos,,drop=FALSE]
  if (nrow(row)!=1L) .ra_stop('Sequencia esgotada/inconsistente; nao sera gerada uma nova lista.')
  entry <- data.frame(numero_alocacao=as.integer(nrow(reg)+1L),identificador=id,
    estrato=stratum,posicao_estrato=pos,grupo=row$grupo,alocado_em_utc=.ra_utc(),
    responsavel=trimws(responsavel),confirmacoes=TRUE,stringsAsFactors=FALSE)
  state$registro <- rbind(reg,entry)
  rownames(state$registro) <- NULL
  .ra_gravar(pasta,state,nrow(state$registro))
  # So retornar/revelar o grupo DEPOIS da confirmacao do registro persistente.
  tryCatch(.ra_csv(pasta,state$registro),error=function(e)
    message('ALOCACAO JA REGISTRADA, mas a exportacao CSV falhou. Feche o Excel e execute exportar_alocacoes_excel(). Nao repita com outro ID.'))
  .ra_recibo(entry)
}

consultar_alocacao <- function(pasta,identificador) {
  id <- .ra_id(identificador)
  pasta <- .ra_pasta(pasta)
  lock <- .ra_travar(pasta)
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  reg <- .ra_ler(pasta)$registro
  row <- reg[reg$identificador==id,,drop=FALSE]
  if (!nrow(row)) .ra_stop('ID ainda nao alocado nesta pasta.')
  .ra_recibo(row)
}

exportar_alocacoes_excel <- function(pasta) {
  pasta <- .ra_pasta(pasta)
  lock <- .ra_travar(pasta)
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  path <- .ra_csv(pasta,.ra_ler(pasta)$registro)
  message('Exportacao de alocacoes ja realizadas: ',path)
  invisible(path)
}

# Somente o pesquisador independente pode acessar este arquivo de alocacoes FUTURAS.
# CSV/RDS nao possuem criptografia propria. A pasta inteira deve ter acesso restrito.
exportar_sequencia_restrita <- function(pasta) {
  pasta <- .ra_pasta(pasta)
  lock <- .ra_travar(pasta)
  on.exit(unlink(lock,recursive=TRUE),add=TRUE)
  path <- file.path(pasta,'SEQUENCIA_FUTURA_RESTRITA.csv')
  if (file.exists(path)) .ra_stop('A exportacao restrita ja existe; nao sera sobrescrita.')
  write.csv2(.ra_ler(pasta)$sequencia,path,row.names=FALSE,fileEncoding='UTF-8')
  Sys.chmod(path,mode='0600')
  message('Sequencia exportada em pasta privada. Nao compartilhar com a equipe clinica: ',path)
  invisible(path)
}
