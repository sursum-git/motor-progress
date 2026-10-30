# Captura física privada de versões

`ContainersVersionAuxSnapshotService.p` persistente recebe dez buffers fixos: itens, empresas, empresas_despesa, despesas_container, descontos_importacao, cta_corren_desconto, nfs_container, docum-est MED, docum-est IMA e situações. `CollectPhysical(master,financial,outPhysical)` exige transação e pai exclusivo; `FinalizeSnapshot(master,physical,cost,outDTO)` combina fotografia física e clone do adapter central sem repetir Math.

Pagamentos são cópia de payment_rows capturados pelo helper Totals com os mesmos CurrencyValue do agregado. Crédito filho segue a razão autorizada de bl_item_custos:16496–16514; crédito do cabeçalho vem do input central e mantém o perfil de cotação da fonte:16642–16651. Zero/unknown no denominador ou autorizado falha; não há fallback fictício. O log_custo do desconto mantém o default0 omitido pelo INSERT legado.

Despesas agrupam IDs iguais quando cálculo/log_custo coincidem; cálculos divergentes para a mesma PK física falham. NFs preservam todos os vínculos e a identidade completa incluindo estabelecimento; banco IMA somente estab='1', caso contrário MED, conforme buscarValoresNFs:16844–16865. O legado gravava apenas a primeira NF e omitia estabelecimento; a integração preserva acervo completo. ERP ausente mantém null e aviso; ambiguidade falha. Domínio usa SHARE-LOCK/NO-WAIT e ERP NO-LOCK; não se alega atomicidade distribuída.

Cabeçalho copia flags/percentual/situação físicos, rastro e cotação selecionados pelo núcleo. cod_tipo_cotacao permanece null por falta de proveniência de uso no legado; não se confunde prioridade com tipo. desc_sit_container conserva a explicação de distribuição observada em bl_item_custos:15758–15765.

GREEN22 checks por cultura AMERICAN/EUROPEAN em12.8 local, RED inicial e de casos fonte em `.runtime/container-version-aux-local`. São testes TT, não publicação. Ainda requer compilação12.2/revisão de precisão e locks físicos antes de habilitar geração real.
