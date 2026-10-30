# Query Consumers Admin UI Implementation Plan

> **For agentic workers:** execute inline with superpowers:executing-plans; one final independent review.

**Goal:** administrar consumidores pela interface, somente tadeu.parreiras e sursum-api/MED/9911.
**Architecture:** página no menu existente, gateway PHP privado com autorização humana/CSRF e sem logs de segredo; wrapper PASOE expõe operações administrativas sobre o mesmo JSON/lock da CLI. Tokens gerados por random_bytes no gateway, somente SHA-256 transmitido ao runtime. Credenciais admin não podem ser alteradas pela tela.
**Tech Stack:** PHP, HTML/JavaScript/Kendo existente, ABL OpenEdge12.2.
**Spec:** ../specs/2026-10-27-query-consumers-admin-ui-design.md (aprovada; usuário autorizou tadeu.parreiras).

## Restrições

- Nenhuma ativação fora de sursum-api/MED/9911. Preservar dirty tree e configuração operacional.
- Não dar acesso a qualquer usuário LDAP nem permitir bypass pelo proxy genérico.
- Nenhum segredo nos logs, URL, localStorage ou recibos. Proteger todos os perfis admin da edição web.
- Compilação oficial .42/OE12.2, publicação com backup/hash, recarga somente MED ocioso.

## Tarefas

- [x] 1. Backend ABL: testes RED de CRUD consumer, revision/conflito, lock CLI, proteção admin, validações, configuração inválida e preservação de bytes em rejeições. Criar DynamicQueryConsumerRegistry.cls e QueryConsumerConfigIo.p; modificar wrapper para rota fixa /SursumDynamicQuery/consumers e validação pública da política. Listar sem hash/token. Criar/editar/rotacionar/revogar com revisão otimista, bloqueio exclusivo e rename atômico, sem desativar expirados implicitamente.
- [x] 2. Gateway PHP: testes RED de usuário exato, CSRF, ação/campos, geração criptográfica/segredo, alvo fixo e bypass. Criar query-consumers-admin.php e query-consumers-admin-lib.php. Reusar sessão e pin TLS; manter segredo fora do registrador genérico, bloqueando consumers no proxy genérico antes de iniciar logs.
- [x] 3. Página: query-consumers.html/js/css e menu-pages.json. Listagem, formulário com seleção de consultas salvas, editar/gerar/rotacionar/revogar, token só na emissão, sem armazenamento persistente. Negação clara a outros usuários. Indicar destino fixo. Testar fluxo de navegador e exclusão do token ao fechar.
- [x] 4. Revisão independente, compilação/testes oficiais em quatro combinações; corrigir falhas. Publicar fontes pertinentes por hash/backup e validar consumer temporário, CSRF, outro usuário, segredos ausentes nos logs, política em outros PASOEs inalterada. Revogar consumidor temporário e preservar os existentes.
- [x] 5. Documentar link, administração autorizada e evidências reais. Atualizar contexto e encerrar acessos temporários.

## Foco da revisão

Identidade/CSRF e acesso direto ao proxy; concorrência com CLI e revisão obsoleta; emissão sem retenção de segredo; credencial admin não editável; alterações sem propagação para outros ambientes.

## Ledger

Ruling: random_bytes no gateway produz token; ABL recebe apenas hash — evita dependência criptográfica de geração no AVM e exposição no log do runtime. Mutex é o mesmo arquivo .lock da CLI, aberto com criação exclusiva por função nativa do SO; substituição atômica não apaga o arquivo anterior antes do rename. Sem alteração de autenticação LDAP existente.

Final GREEN: compilacao oficial12.2.12,34registry+52policy em cada4combinacoes;18PASOEadministrativos;20navegadorLDAPreal;49PHPadmin+19helper no servidorpublicado;CLI5regressoes. OitoartefatosABL e oitoarquivosweb porhash; consumidoresde exercicio removidos e bytesoriginais restaurados. Revisaoindependente semP1/P2. Recibo temp/query-consumers-ui-20261027/final-verification.json.

Ruling: runtimeISO8859-1 exige parserbodyUTF8; getQueryStoreRoot legado usa separadoresWindowsliterais no cwd que SEARCH nao inclui: nativeaccess resolve leitura semmudarPROPATH. Evidencias: probe12.2Linux e testePASOEreal. ParaPHP, credencialrelocada semtrocarbytes de/etc para web7/private dentrodoopen_basedir;ACLweb7somenteleitura,semalterarconfigPHP. ProxySSLlocalexistente exigiu sinalXFP restritoaloopback. A validacaoCLI isolada nao substitui o navegador comLDAP/poolreal, que passou20checks finais.
