# Administração web dos consumidores e tokens

Estado: formato aprovado pelo usuário em 27/10/2026, com administração inicialmente exclusiva do usuário LDAP `tadeu.parreiras` e destino somente sursum-api/MED/9911.

## Objetivo e escopo

Adicionar uma página Consumidores e tokens no Query Progress, seguindo a navegação e os componentes da página Requisições. Política restrita ao PASOE sursum-api/MED/9911, conforme determinação permanente. Não alterar a política de outros contextos ou instâncias.

## Abordagens

Recomendação: página no site existente, usando a sessão LDAP atual e operações administrativas autenticadas no próprio PASOE para gerenciar a configuração operacional. O backend web exige uma lista explícita de administradores humanos; a credencial técnica administrativa permanece privada no servidor. A mesma restrição deve valer para acesso direto às novas ações administrativas pelo proxy, sem depender apenas da visibilidade do menu. É preciso publicar e validar os novos fontes ABL/PHP.

Alternativa: página web alterando diretamente o arquivo por montagem remota ou SSH. Evita novas operações PASOE, mas exige dar ao servidor web acesso ao arquivo operacional e introduz outro caminho administrativo. Não recomendada, pois a configuração hoje pertence ao runtime PASOE e a CLI confiável.

## Funcionalidades propostas

- Listar consumidores com identificador, perfil, consultas permitidas, validade e situação (ativo, expirado ou revogado), sem tokens ou hashes.
- Criar consumidor de integração escolhendo consultas salvas autorizadas e validade.
- Editar consultas e validade; revogar e rotacionar token com confirmação explícita.
- Mostrar novo token somente na resposta de criação/rotação, com botão Copiar; sem persistência no navegador, URL, logs de requisições ou histórico visível. Após fechar, só será possível gerar outro token.
- Preservar a credencial de serviço web-query-admin: não permitir revogação/rotação/edição pela tela comum, evitando interromper a interface ou emitir credencial administrativa para consumidores.
- Consumidores criados pela página têm perfil consumer; novos administradores técnicos permanecem sob administração confiável.

## Proteções e persistência

Autorização humana verificada no servidor em cada operação, além do perfil técnico admin no PASOE. CSRF nas mutações, respostas no-store e nenhum segredo capturado pelos logs do proxy. Novas operações usam um caminho próprio protegido que não encaminha respostas com tokens pelo registrador genérico. Validar rigorosamente identificador, códigos, validade e estado; gravação atômica com bloqueio compartilhado com a CLI e proteção contra alterações concorrentes, sem sobrescrever configurações inválidas. Nunca depender de valores de identidade enviados pelo navegador.

A configuração SHA-256 continua única no PASOE; mudanças entram em vigor sem recarga. A lista de administradores humanos contém somente o login LDAP tadeu.parreiras, autorizado expressamente pelo usuário. Menu e tela indicam o destino fixo sursum-api/MED; não há seletor para propagar a política.

A página exige HTTPS. O vhost SSL existente sobrescreve X-Forwarded-Proto=https e encaminha para 127.0.0.1:80; o gateway aceita esse sinal somente de loopback, além de HTTPS nativo, sem confiar em cabeçalhos de clientes remotos. A credencial técnica fica na pasta privada do site, fora de DocumentRoot e dentro de open_basedir, com ACL de leitura específica para o usuário PHP web7.

## Validação

Testes positivos e negativos de autorização humana, CSRF, concorrência, proteção do consumidor de serviço, segredo exibido somente na emissão e ausência em logs. Compilar no OpenEdge 12.2 oficial, publicar e validar no PASOE real; exercício com consumidor temporário sem tocar nos existentes e revogação ao encerrar. Validar a página no navegador e a permanência do comportamento dos outros PASOEs.
