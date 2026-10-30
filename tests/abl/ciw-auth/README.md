# Testes CIW de autenticacao

Compilar em OpenEdge12.2/.42, com os fontes de produto e testes copiados para
staging plano, OpenEdge.Net.pl no PROPATH e espec conectado. Executar
CompileCiwAuthentication.p; exigir COMPILER:ERROR=no e PASS108+31 por cultura.
CiwAuthenticationEncodingTest.p deve executar com CPINTERNAL UTF-8 e ISO8859-1,
contra o mesmo servico .r12.2: PASS3 em cada um. Somente TT; nao cria usuarios.
VerifyCiwAuthenticationNoPayload.p le apenas contagem da rota exclusiva, sem
payloads/senhas. Ferramentas e manifestos: conversao-sc/tools/construtor-local/
prepare-ciw-auth-compile.py e prepare-ciw-auth-delta.py. Nenhum fixture publicado.
Ver docs/CIW_AUTHENTICATION.md para estado real, caminhos e pendencia positiva.
