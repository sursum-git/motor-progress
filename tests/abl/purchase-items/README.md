# Testes isolados dos itens de compra

As cinco suítes acrescentam104verificações: ID11, writer47, reader9, finance19 e runtime18. Usam apenas tabelas temporárias, NUM-DBS=0. O build oficial de22/10 executou junto às9suítes anteriores:371verificações emcada4combinações de cultura/codepage OpenEdge12.2.

Prepare staging privado com os programas atuais, includes, fixtures de purchase-orders/purchase-payments/container-panel e estes testes. `PreparePurchaseItemsHost.ps1` reutiliza o gerador do cadastro pai e troca somente as duas sequências por callbacks TT; gera ambos os nomes de host exigidos pelas regressões. Execute cada suíte com NUMERIC-FORMAT AMERICAN/EUROPEAN e CPINTERNAL UTF-8/ISO8859-1. Nunca publique hosts ou fixtures, nunca conecte estas suítes ao espec operacional.

O pacote/runner exato e hashes do build validado estão no workspace de conversão `.runtime/purchase-items-20261022/build2/`, e o preparador rastreável em `.runtime/purchase-items-20261022/prepare-package.py`. Scripts antigos com caminhos candidatos são diagnósticos históricos; compilados publicáveis são exclusivamente os12.2conferidos no manifesto.
