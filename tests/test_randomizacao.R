# Testes de integracao do alocador. Executar da raiz do repositorio.
# Todas as sementes e identificacoes abaixo sao SINTETICOS, nunca para o ensaio.
# Todos os registros sao criados em tempdir() e removidos ao final.

run_randomization_tests <- function() {
  source_path <- normalizePath('randomizacao.R', mustWork=TRUE)
  api <- new.env(parent=globalenv())
  sys.source(source_path, envir=api)
  paths <- character()
  results <- list()
  on.exit(unlink(paths, recursive=TRUE, force=TRUE), add=TRUE)
  check <- function(name, expression) {
    if (!isTRUE(force(expression))) stop('FALHOU: ', name, call.=FALSE)
    results[[length(results)+1L]] <<- data.frame(test=name,result='PASS')
  }
  fails <- function(expression) inherits(tryCatch(force(expression), error=identity),'error')
  fresh <- function(seed=73101L,total=66L,blocks=c(6L,8L)) {
    p <- tempfile('randomizacao_teste_')
    paths <<- c(paths,p)
    suppressMessages(api$iniciar_randomizacao(p,blocks,total=total,semente=seed))
    p
  }
  state_path <- function(p,n) file.path(p,'estados',sprintf('estado_%06d.rds',n))
  latest <- function(p) {
    files <- sort(list.files(file.path(p,'estados'),pattern='^estado_[0-9]{6}[.]rds$',full.names=TRUE))
    readRDS(tail(files,1))
  }
  allocate <- function(p,id,stratum='F_LEVE',confirm=TRUE) suppressMessages(
    api$alocar_participante(p,id,stratum,responsavel='OPERADOR_TESTE',confirmacoes=confirm))
  same_receipt <- function(a,b) {
    rownames(a) <- rownames(b) <- NULL
    identical(a,b)
  }

  # Reproducibilidade e equilibrio sao avaliados na lista, sem publicar a lista.
  p <- fresh()
  q <- fresh()
  plan <- readRDS(state_path(p,0))
  check('Mesmo seed sintetico reproduz a sequencia',
        identical(plan$sequencia,readRDS(state_path(q,0))$sequencia))
  check('Quatro estratos e capacidade para toda a meta em qualquer estrato',
        setequal(unique(plan$sequencia$estrato),c('F_LEVE','F_MODERADA','M_LEVE','M_MODERADA')) &&
        all(table(plan$sequencia$estrato)>=66L))
  blocks <- split(plan$sequencia,interaction(plan$sequencia$estrato,plan$sequencia$bloco,drop=TRUE))
  check('Cada bloco completo tem alocacao 1:1 e tamanho predefinido',
        all(vapply(blocks,function(x) nrow(x)==unique(x$tamanho_bloco) &&
          unique(x$tamanho_bloco) %in% c(6L,8L) &&
          sum(x$grupo=='SHAM')==nrow(x)/2 &&
          sum(x$grupo=='ELETROACUPUNTURA')==nrow(x)/2,logical(1))))
  check('Inicializar novamente nao substitui o plano',
        fails(api$iniciar_randomizacao(p,c(4L,8L),semente=2L)) &&
        identical(readRDS(state_path(p,0)),plan))
  check('Inicializar nao aloca participantes', nrow(latest(p)$registro)==0L)
  in_git <- tempfile('randomizacao_pasta_invalida_',tmpdir=getwd())
  paths <- c(paths,in_git)
  check('Impede guardar sequencia real dentro do repositorio Git',
        fails(api$iniciar_randomizacao(in_git,c(6L,8L),semente=1L)))
  for (bad in list(c(4L,4L),c(5L,8L),c(2L,6L),4L,c(4L,NA_integer_))) {
    trial <- tempfile('randomizacao_invalida_')
    paths <- c(paths,trial)
    check(paste('Rejeita tamanhos invalidos',paste(bad,collapse='_')),
          fails(api$iniciar_randomizacao(trial,bad,semente=1L)))
  }
  check('Confirmacoes basais obrigatorias antes da primeira alocacao',
        fails(allocate(p,'P001',confirm=FALSE)) && nrow(latest(p)$registro)==0L)
  for (bad in list(1L,'','=FORMULA','@FORMULA','../arquivo','P 001')) {
    check(paste('Rejeita ID invalido',paste(bad,collapse='_')),
          fails(allocate(p,bad)) && nrow(latest(p)$registro)==0L)
  }
  check('Estrato desconhecido nao consome uma posicao',
        fails(allocate(p,'P001','F_GRAVE')) && nrow(latest(p)$registro)==0L)

  a <- allocate(p,'  p001  ','f_leve')
  b <- allocate(p,'0002','M_MODERADA')
  c <- allocate(p,'P003','F_LEVE')
  check('ID normalizado e zeros iniciais preservados',
        identical(a$identificador,'P001') && identical(b$identificador,'0002'))
  check('Cada estrato consome sua propria proxima posicao',
        identical(c(a$grupo,c$grupo),plan$sequencia$grupo[plan$sequencia$estrato=='F_LEVE'][1:2]) &&
        identical(b$grupo,plan$sequencia$grupo[plan$sequencia$estrato=='M_MODERADA'][1]) &&
        identical(latest(p)$registro$posicao_estrato,c(1L,1L,2L)))
  again <- allocate(p,'p003','f_leve')
  check('Repeticao do ID devolve o mesmo recibo sem novo sorteio',
        same_receipt(c,again) && nrow(latest(p)$registro)==3L)
  check('ID ja alocado nao pode mudar de estrato',
        fails(allocate(p,'P003','M_LEVE')) && nrow(latest(p)$registro)==3L)
  api2 <- new.env(parent=globalenv())
  sys.source(source_path,envir=api2)
  check('Recarregar o script preserva as alocacoes',
        same_receipt(a,suppressMessages(api2$consultar_alocacao(p,'P001'))))

  # Processo R independente: consulta e nova alocacao no mesmo estado persistente.
  child_script <- file.path(p,'processo_teste.R')
  child_result <- file.path(p,'resultado_processo.rds')
  quoted <- function(x) encodeString(x,quote='"')
  writeLines(c(paste0('source(',quoted(source_path),')'),
    paste0('p <- ',quoted(p)),
    'a <- consultar_alocacao(p,"P001")',
    'b <- alocar_participante(p,"P004","M_LEVE","PROCESSO_TESTE",confirmacoes=TRUE)',
    paste0('saveRDS(list(a=a,b=b),',quoted(child_result),')')),child_script)
  rscript <- file.path(R.home('bin'),'Rscript')
  process <- system2(rscript,c('--vanilla',shQuote(child_script)),stdout=TRUE,stderr=TRUE)
  exit_status <- attr(process,'status')
  if (is.null(exit_status)) exit_status <- 0L
  check('Novo processo R consegue ler e continuar sem reiniciar a lista',
        exit_status==0L && file.exists(child_result) &&
        same_receipt(readRDS(child_result)$a,a) &&
        readRDS(child_result)$b$numero_alocacao==4L && nrow(latest(p)$registro)==4L)
  check('Consulta desconhecida nao aloca participante',
        fails(api$consultar_alocacao(p,'AUSENTE')) && nrow(latest(p)$registro)==4L)

  csv <- suppressMessages(api$exportar_alocacoes_excel(p))
  exported <- read.csv2(csv,colClasses='character',check.names=FALSE)
  check('Exportacao Excel contem apenas alocacoes realizadas e preserva IDs',
        nrow(exported)==4L && identical(exported$identificador,c('P001','0002','P003','P004')))
  writeLines('arquivo CSV editado externamente',csv)
  d <- allocate(p,'P005','F_MODERADA')
  check('Edicao no CSV nao interfere na lista nem no proximo sorteio',
        d$numero_alocacao==5L &&
        identical(d$grupo,plan$sequencia$grupo[plan$sequencia$estrato=='F_MODERADA'][1]))
  restricted <- suppressMessages(api$exportar_sequencia_restrita(p))
  check('Exportacao restrita reproduz a sequencia e nao sobrescreve arquivo existente',
        nrow(read.csv2(restricted))==nrow(plan$sequencia) &&
        fails(api$exportar_sequencia_restrita(p)))

  # Uma trava existente deve bloquear, sem expiracao ou remocao automatica.
  lock <- file.path(p,'.trava_alocacao')
  dir.create(lock)
  check('Trava existente impede escrita e e preservada',
        fails(allocate(p,'P006')) && dir.exists(lock) && nrow(latest(p)$registro)==5L)
  unlink(lock,recursive=TRUE)

  # Simula erro antes da confirmacao em disco; nenhum recibo pode ser liberado.
  write_fail <- fresh(seed=73107L)
  real_write <- api$.ra_gravar
  api$.ra_gravar <- function(...) stop('Falha simulada antes do commit')
  check('Falha antes do commit nao consome posicao e libera a trava',
        fails(allocate(write_fail,'ESCRITA01')) &&
        nrow(latest(write_fail)$registro)==0L &&
        !dir.exists(file.path(write_fail,'.trava_alocacao')))
  api$.ra_gravar <- real_write
  after_fail <- allocate(write_fail,'ESCRITA01')
  check('Retomada apos falha anterior ao commit usa a primeira posicao',
        after_fail$numero_alocacao==1L && nrow(latest(write_fail)$registro)==1L)

  # Simula indisponibilidade do CSV: o commit RDS ja foi confirmado.
  export_fail <- fresh(seed=73102L)
  dir.create(file.path(export_fail,'alocacoes_realizadas.csv'))
  e <- suppressWarnings(allocate(export_fail,'FALHA01'))
  check('Falha de exportacao depois do commit nao perde a alocacao',
        nrow(latest(export_fail)$registro)==1L &&
        same_receipt(e,api$consultar_alocacao(export_fail,'FALHA01')))
  check('Repetir depois de falha de exportacao nao consome nova posicao',
        same_receipt(e,allocate(export_fail,'FALHA01')) && nrow(latest(export_fail)$registro)==1L)
  unlink(file.path(export_fail,'alocacoes_realizadas.csv'),recursive=TRUE)
  recovered <- suppressMessages(api$exportar_alocacoes_excel(export_fail))
  check('Exportacao pode ser refeita apos falha sem realocar',
        nrow(read.csv2(recovered))==1L && nrow(latest(export_fail)$registro)==1L)

  corrupt <- fresh(seed=73103L)
  allocate(corrupt,'CORR01')
  writeBin(charToRaw('NOT AN RDS'),state_path(corrupt,1L))
  check('Estado mais recente corrompido bloqueia sem retorno silencioso ao anterior',
        fails(api$consultar_alocacao(corrupt,'CORR01')) &&
        fails(allocate(corrupt,'CORR02')) && !file.exists(state_path(corrupt,2L)))
  gap <- fresh(seed=73104L)
  allocate(gap,'GAP01'); allocate(gap,'GAP02')
  unlink(state_path(gap,1L))
  check('Lacuna no historico bloqueia alocacoes',
        fails(allocate(gap,'GAP03')) && !file.exists(state_path(gap,3L)))
  changed <- fresh(seed=73105L)
  allocate(changed,'HIST01'); allocate(changed,'HIST02')
  altered <- readRDS(state_path(changed,2L))
  altered$registro$responsavel[1] <- 'ALTERADO'
  saveRDS(altered,state_path(changed,2L))
  check('Alteracao retroativa em registro anterior e detectada',fails(allocate(changed,'HIST03')))
  changed_plan <- fresh(seed=73106L)
  allocate(changed_plan,'PLANO01')
  altered <- readRDS(state_path(changed_plan,1L))
  altered$config$total <- 68L
  saveRDS(altered,state_path(changed_plan,1L))
  check('Configuracao nao pode mudar entre estados',fails(allocate(changed_plan,'PLANO02')))

  # Fixture deliberadamente desequilibrada no corte 66: detecta teto errado 33/braco.
  quota <- NULL
  for (seed in 73110:73130) {
    candidate <- fresh(seed=seed,blocks=c(8L,10L))
    s <- latest(candidate)$sequencia
    first66 <- s$grupo[s$estrato=='F_LEVE'][1:66]
    if (max(table(first66))>33L) {quota <- candidate; break}
  }
  stopifnot(!is.null(quota))
  for (i in seq_len(66L)) allocate(quota,sprintf('LIM%03d',i))
  check('Permite chegar a 66 sem impor cota artificial de 33 por grupo',
        nrow(latest(quota)$registro)==66L && max(table(latest(quota)$registro$grupo))>33L)
  check('O participante 67 e bloqueado sem modificar os 66 anteriores',
        fails(allocate(quota,'LIM067')) && nrow(latest(quota)$registro)==66L &&
        !file.exists(state_path(quota,67L)))
  check('Consulta/repeticao de participante existente funciona apos atingir o limite',
        same_receipt(api$consultar_alocacao(quota,'LIM066'),allocate(quota,'LIM066')))

  set.seed(891L)
  old_rng <- .Random.seed
  auto <- tempfile('randomizacao_auto_teste_')
  paths <- c(paths,auto)
  suppressMessages(api$iniciar_randomizacao(auto,c(6L,8L)))
  check('Inicializacao automatica preserva o estado RNG do usuario',identical(old_rng,.Random.seed))
  check('Semente privada automatica e registrada sem alocar pacientes',
        is.numeric(latest(auto)$config$semente) && length(latest(auto)$config$semente)==1L &&
        nrow(latest(auto)$registro)==0L)
  do.call(rbind,results)
}

randomization_test_results <- run_randomization_tests()
print(randomization_test_results,row.names=FALSE)
cat('\n',nrow(randomization_test_results),' testes de randomizacao aprovados. Registros temporarios removidos.\n',sep='')
