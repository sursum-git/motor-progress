# Composição privada de versões

## Atualização coordenada12.2 —16/10/2026

Os registros12.8/RED abaixo são históricos. Lote coerente `.runtime/container-panel-coherent-compiled-20261016-v2/` compilou52fontes12.2 sem erro;24suites e1962checks por cultura passaram. Composição34 e MissingActual7 passaram após correção separada do coletor: histórico opcional unknown fica JSONnull, sem mudar D() nos obrigatórios. Inputs/Close175, Context11 e Runtime12 também passaram no12.2. Apenas a correção do coletor de leitura foi publicada/validada no PASOE; helpers de escrita continuam privados, sem rota, sequência ou negócio real executado. Ver memória de retomada para manifests atuais.


O runtime é o único orquestrador. Primeiro VersionService cria situação1, persiste todos os filhos, marca situação2 e passa IDs físicos para ApplyVersionDistribution. O serviço central de distribuição aplica seu plano. Se requiredNewSnapshot=true, o runtime chama o MESMO VersionService com allow_nested=true; essa segunda fotografia passa por version_check, que não grava e exige delta persistível zero. Não há terceira fotografia, recursão livre, fórmula ou writer duplicado. enable_distribution é privado/defaultfalse; produção usa companhia do container e phSequenceProvider=?; fixtures TT podem substituir apenas as sequências por callbacks fixos.

Composição só retorna efeitos pendentes ao ancestral. Auditoria raiz aparece após commit; falha em qualquer etapa desfaz duas versões, todos os snapshots filhos, ledger, despesa gerenciada, efeitos fiscais e mestre. Sequências consumidas em transação não são revertidas; testes usam contadores TT e nenhum ID real. GetStatus não executa processo. Nenhuma rota ou página foi conectada nesta etapa.

GREEN local12.8 por cultura: Composition34, Runtime12, Version186, Aux22 e Context11 (265checks/cultura). O teste integrado usa os serviços reais; a borda fiscal controlada pode mudar uma despesa na segunda chamada para provocar instabilidade observável. Residual com três itens reparte10,01 e persiste3,34 por item; o restante subcentavo não pede nova fotografia, conforme plano do núcleo central. Um followup chamado isoladamente é recusado antes de acessar sequência. Runtime pode ser reutilizado após rollback, pois contador/estado ativo são restaurados em FINALLY.

Executar os runners correspondentes em staging isolado com os .p/.i do manifesto, usando _progres.exe -b -p CompileContainersVersionCompositionTests.p -T . -cpinternal UTF-8 -cpstream UTF-8. Exigir COMPILER:ERROR=no para todos os dez componentes, PASS AMERICAN, PASS EUROPEAN e PASS COMPOSITION. Exitcode não é prova. Runners/testes não são publicáveis.

## RED conhecido separado: realizado histórico desconhecido

Fonte fora da ownership do provider: ContainersCustoReadService.p:463. O Collector anexa vl_unit_real_versao por D(phItemCustos,"vl_unit_realiz"), cujo contrato rejeita ABL?. A primeira fotografia pode validamente persistir realizado null/actual_complete=false. Na coleta da segunda fotografia, o campo histórico desconhecido faz falhar até cálculo atual/perfilversion. Não converter null para zero.

Reprodução mínima: dois itens do mesmo container, preços/quantidades válidos e pool distribuível; documento ERP possui ERP1 e não possui ERP2. Primeiro adapter retorna null no realizado de ERP2, writer preserva?; distribuição solicita followup; segundo Collector lê ICC.vl_unit_realiz? e falha. A raiz desfaz a composição. O teste separado ContainersVersionCompositionMissingActualTest.p inclui o mesmo fixture, ativa somente esse cenário e espera sucesso para virar GREEN após correção da dependência. Hoje ele compila e permanece RED com “Valor numerico desconhecido: vl_unit_realiz”.

Runner: CompileContainersVersionMissingActualTests.p. Evidência: .runtime/container-version-missing-actual-local/compile-containers-version-missing-actual.log. Esse caso não participa da contagem GREEN34 e consta como pendência no manifesto. Root corrige Collector de forma separada; este trabalho não modifica Math, Collector, Adapter, Distribution, Fiscal, Boundary ou includes canônicas. Até corrigir/revalidar, não declarar composição com realizado ausente pronta para produção.
