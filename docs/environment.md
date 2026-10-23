# Configuração da nuvem

R 4.5.0 foi instalado localmente nesta instância Debian 13 amd64 por
`scripts/setup_r_debian.sh`. O índice APT foi verificado pelo chaveiro Debian,
e o pacote `r-base-core_4.5.0-3_amd64.deb` passou na conferência SHA256.
A reinstalação do mesmo pacote e o teste funcional de R foram executados.

Os campos `install_script` e `start_skill` foram salvos no rascunho da
configuração da nuvem. A gravação foi confirmada pela ferramenta, mas não
publica nem aplica a configuração a futuras tarefas automaticamente.
Para ativar essa configuração, revise e salve as alterações nas configurações
do ambiente e depois publique o ambiente pela interface.

O cálculo completo foi executado nesta instância. A restauração em uma nova
tarefa após publicação não foi testada. Não há serviços para iniciar,
credenciais a inserir ou alterações de rede necessárias.
