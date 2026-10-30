# Opções de itens de pedido para alocação

Serviço somente leitura `ContainersItensOptionsService.p`. ABI fixa:

```text
INPUT phMaster HANDLE          // espec.pp-container
INPUT phItems HANDLE           // espec.itens_container
INPUT phPurchaseItems HANDLE   // espec.itens_proc_compra
INPUT phPurchases HANDLE       // espec.procs_compra
INPUT poRequest JsonObject     // {operation:"read",container_id:INTEGERpositivo}
OUTPUT poResponse JsonObject
```

Wrapper autenticado fornece os quatro buffers. Request permite somente operation=read exata e container_id número inteiro positivo int32; resource/empresa/fornecedor/listas/filtros/caminhos não pertencem ao contrato interno. Root compõe wrapper e registro de operação, sem receber handles ou nomes do navegador. Este serviço não autentica nem executa alocação.

Elegibilidade: item de compra tem codigo_erp preenchido, processo pai existente e saldo global arredondado a2casas positivo **ou** já existe itens_container desse item no container atual. Saldo=ROUND(qt_comprada−SUM(qt_alocada de todos os containers),2). Não filtrar por empresa/fornecedor. Cadastros estrangeiros são válidos e aparecem somente como rótulo derivado. Itens já alocados ao CID aparecem mesmo com saldo0/negativo para manter dropdown readonlyOnEdit/copyFields; isso não permite dupla inclusão, que o writer recusa. Sem código ERP ou sem processo pai continuam excluídos, inclusive se o vínculo antigo estiver inválido.

Resposta: success=true,data=[{item_proc_compra_id:INTEGER,label:STRING,saldo_disponivel_texto:STRING}]. Ordenação por item_proc_compra_id. label contém pedido, código ERP, descrição Unicode, saldo, IDs de empresa/fornecedor e “já alocado” quando aplicável. saldo_disponivel_texto é pt-BR com duas casas, independente de SESSION:NUMERIC-FORMAT. Quantidade desconhecida causa erro, sem fabricar zero. Nenhuma fórmula de custo/fiscal/versões foi copiada.

Todas as leituras são NO-LOCK. A consulta não consome sequência, grava negócio, abre transação própria ou usa cache. Saldo de apresentação é uma fotografia sem garantia concorrente; o serviço de gravação deve recalcular o saldo global sob seus locks e validar a quantidade positiva explícita. O serviço não substitui a autorização de manutenção nem os guards de container/duplicidade.

Erros sem data parcial: ITENS_OPTIONS_INVALID_REQUEST/422; ITENS_OPTIONS_NOT_FOUND/404; ITENS_OPTIONS_CONFIGURATION/503 para handles/campos/tipos inválidos; ITENS_OPTIONS_DATA_INVALID/422 para origem desconhecida; ITENS_OPTIONS_RESULT_LIMIT/422 quando haveria mais de5.000 opções. Até5.000 retorna lista completa; acima disso exige evolução explícita da consulta/pesquisa, nunca truncamento silencioso. Wrapper deve propagar erro esclarecedor.

Campos físicos conferidos em schema/schema-{pp-container,itens_container,itens_proc_compra,procs_compra}.json. Pedidos usam proc_compra_id/empresa_id/fornecedor_id; quantidade comprada e alocada são DECIMAL2. Fixture TT possui DECIMAL10 propositalmente para provar ROUND2 depois da soma; não representa mudança de schema físico. Regras de seleção herdadas de control_selec_proc_compra e grid_itens_proc_compra_selecao: global, código ERP preenchido, saldo disponível. A inclusão de atuaisCID é o requisito de apresentação da edição nativa.

Diagnóstico TDD: REDstub compilado, GREEN45 checks em AMERICAN/EUROPEAN no12.8 local, UTF8;2fontes sem COMPILER:ERROR. Inclui outrosCID no saldo, contexto entre pais, zero/negativo atual, FKpai excluída, ERP vazio, empresa/fornecedor diferentes, arredondamento, contrato fechado, buffer inválido, quantidades desconhecidas, ausência de cache e limite5.000/5.001. Evidência em .runtime/container-items-20261017/options-local/. Testes/runners não são publicáveis; nenhum ID real foi consumido.

Preparado somente no workspace. Root ainda deve compilar12.2/.42, integrar wrapper e validar PASOE sursum-api/med. Nenhuma publicação, código canônico ou negócio real foi alterado por esta entrega ABL.
