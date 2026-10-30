<?php
declare(strict_types=1);

const QUERY_API_BASE='https://iol.imatextil.com.br/query-progress';

function queryApiCatalog(?array $directories=null):array
{
    $directories??=[dirname(__DIR__).'/sursum-api/querys',__DIR__.'/sursum-querys'];
    $catalog=[];
    foreach($directories as $directory)foreach(glob($directory.'/*.json')?:[] as $file){
        $id=basename($file,'.json');
        if(isset($catalog[$id]))continue;
        $data=json_decode((string)file_get_contents($file),true,64,JSON_THROW_ON_ERROR);
        $code=$data['code']??$id;
        if(!is_string($code)||preg_match('/\A[A-Za-z0-9_.-]{1,128}\z/D',$code)!==1)throw new RuntimeException('Codigo invalido no catalogo.');
        $query=$data['query']??$data;
        $filters=[];
        foreach(($data['externalFilters']??$query['externalFilters']??[]) as $filter){
            $name=(string)($filter['name']??'');$source=(string)($filter['source']??'querystring');
            if($name===''||$source==='')throw new RuntimeException('Filtro invalido no catalogo.');
            $key=$source.':'.$name;
            $filters[$key]=['name'=>$name,'source'=>$source,'required'=>(bool)($filter['required']??false)||($filters[$key]['required']??false)];
        }
        $fields=[];
        foreach(($query['select']??[]) as $field){
            $alias=$field['outputAlias']??$field['field']??'';
            if(is_string($alias)&&$alias!=='')$fields[]=$alias;
        }
        // Only public contract metadata. Never serialize database/source/SQL definitions.
        $parallel=$data['asyncParallel']??null;
        $parallelPublic=null;
        if(is_array($parallel)&&($parallel['enabled']??false)===true){
            $parallelPublic=['maxWorkers'=>(int)($parallel['maxWorkers']??0),'maxPartitions'=>(int)($parallel['maxPartitions']??0),'maxPartitionRecords'=>(int)($parallel['maxPartitionRecords']??0),'maxPartitionBytes'=>(int)($parallel['maxPartitionBytes']??0),'maxResultBytes'=>(int)($parallel['maxResultBytes']??0)];
        }
        $catalog[$id]=['code'=>$code,'name'=>(string)($data['name']??$data['description']??$code),'status'=>(string)($data['status']??'ready'),'filters'=>array_values($filters),'fields'=>array_values(array_unique($fields)),'cursorEligible'=>queryApiCursorEligible($query),'parallel'=>$parallelPublic];
    }
    ksort($catalog,SORT_NATURAL|SORT_FLAG_CASE);
    return array_values($catalog);
}

function queryApiCursorEligible(array $query):bool
{
    foreach(($query['pipeline']??[]) as $step)if(!in_array(strtolower((string)($step['type']??'')),['source','join','select','filter','sort','limit','map'],true))return false;
    foreach(($query['joins']??[]) as $join)if(strtolower((string)($join['type']??'inner'))!=='inner')return false;
    $tables=[];foreach(($query['sources']??[]) as $source){$name=strtolower((string)($source['nome']??''));if(isset($tables[$name]))return false;$tables[$name]=true;}
    return (bool)$tables;
}

function queryApiFilterExample(string $name):string
{
    return match($name){'estabelecimento'=>'502','deposito'=>'ARM','item'=>'130062','referencia'=>'004','dataInicial'=>'2021-01-01','dataFinal'=>'2025-12-31','produto'=>'130062','nr-container','nr_container'=>'INFORME_O_CONTAINER','dt_referencia'=>gmdate('Y-m-d'),default=>'INFORME_O_VALOR'};
}

function queryApiExample(array $query):array
{
    $groups=[];
    foreach($query['filters'] as $filter)$groups[$filter['source']][$filter['name']]=queryApiFilterExample($filter['name']);
    return ['code'=>$query['code'],'paginationMode'=>'offset','paginate'=>true,'page'=>1,'pageSize'=>100,'parameters'=>$groups?:new stdClass()];
}

function queryApiRequestSchema(array $query):array
{
    $groups=[];$requiredGroups=[];
    foreach($query['filters'] as $filter){
        $source=$filter['source'];$name=$filter['name'];
        $groups[$source]??=['type'=>'object','additionalProperties'=>false,'properties'=>[]];
        $groups[$source]['properties'][$name]=['type'=>'string','description'=>$name==='referencia'?'Referencia do estoque (cod-refer). Preserve zeros a esquerda.':'Filtro '.$name.'. Informe como texto.','example'=>queryApiFilterExample($name)];
        if($filter['required']){$groups[$source]['required'][]=$name;$requiredGroups[$source]=true;}
    }
    $parameters=['type'=>'object','additionalProperties'=>false,'properties'=>$groups?:new stdClass()];
    if($requiredGroups)$parameters['required']=array_keys($requiredGroups);
    return ['type'=>'object','title'=>$query['code'],'description'=>'Consulta salva '.$query['code'].'. Estado: '.$query['status'].'. Exige permissao do consumidor para este codigo. Campos de saida: '.implode(', ',$query['fields']).'.','additionalProperties'=>false,'required'=>['code',...($requiredGroups?['parameters']:[])],'properties'=>['code'=>['type'=>'string','enum'=>[$query['code']]],'parameters'=>$parameters,'paginationMode'=>['type'=>'string','enum'=>($query['cursorEligible']?['offset','cursor']:['offset']),'default'=>'offset','description'=>($query['cursorEligible']?'Cursor exige chave unica validada em runtime; nao envie page nem paginate:false.':'Cursor indisponivel nesta consulta com transformacao/joins incompativeis.')],'cursor'=>['type'=>'string','maxLength'=>16384,'description'=>'Somente no modo cursor. Omita ou deixe vazio na primeira chamada; depois envie nextCursor, mantendo filtros e pageSize. Validade900s.'],'paginate'=>['type'=>'boolean','default'=>true,'description'=>'false retorna todos os registros filtrados, sem limite de pagina. page/pageSize sao ignorados; limites de tempo/tamanho continuam.'],'page'=>['type'=>'integer','minimum'=>1,'maximum'=>1000000,'description'=>'Pagina a partir de 1. Opcional: usa o valor salvo quando omitido.'],'pageSize'=>['type'=>'integer','minimum'=>1,'maximum'=>1000,'description'=>'Registros por pagina, maximo1000. Opcional: tamanho salvo limitado a1000.'],'webhookDelivery'=>['type'=>'string','enum'=>['full','manifest'],'description'=>'Somente com execution:async. full envia o resultado ao webhook; manifest envia metadados e URL de download autenticado.']],'example'=>queryApiExample($query)];
}

function queryApiOpenApi(array $catalog):array
{
    $schemas=[];$examples=[];$oneOf=[];
    foreach($catalog as $query){$code=$query['code'];$schemas[$code]=queryApiRequestSchema($query);$examples[$code]=['summary'=>$query['name'],'value'=>queryApiExample($query)];$oneOf[]=['$ref'=>'#/components/schemas/'.$code];if($query['cursorEligible']){$value=queryApiExample($query);unset($value['page'],$value['paginate']);$value['paginationMode']='cursor';$value['cursor']='';$examples[$code.'-cursor']=['summary'=>$query['name'].' — cursor','value'=>$value];}}
    $errors=[];
    foreach([400=>'JSON ou parametros invalidos',401=>'Token ausente, vencido ou revogado',403=>'Consulta sem permissao',413=>'Corpo muito grande',415=>'Content-Type invalido',426=>'HTTPS obrigatorio',429=>'Limite de emissao',502=>'Falha no gateway',503=>'Servico indisponivel',504=>'Tempo excedido'] as $code=>$description)$errors[(string)$code]=['description'=>$description,'content'=>['application/json'=>['schema'=>['type'=>'object','additionalProperties'=>true]]]];
    $spec = ['openapi'=>'3.0.3','info'=>['title'=>'Consultas Sursum / MED','version'=>'1.2.0','description'=>count($catalog).' consultas salvas do catalogo atual. Todas usam POST /api/query.php com code e parameters; os filtros ficam no JSON, nao na URL. Somente sursum/MED. A documentacao nao concede permissoes. Para consultas de container, substitua INFORME_O_CONTAINER por um valor real. Tokens duram 900s e nao estendem a autorizacao do consumidor.'],'servers'=>[['url'=>QUERY_API_BASE]],'tags'=>[['name'=>'Autenticacao'],['name'=>'Consultas salvas']],'paths'=>[
        '/api/token.php'=>['post'=>['tags'=>['Autenticacao'],'operationId'=>'obterToken','summary'=>'Obter token de 15 minutos','security'=>[],'requestBody'=>['required'=>true,'content'=>['application/x-www-form-urlencoded'=>['schema'=>['type'=>'object','additionalProperties'=>false,'required'=>['grant_type','client_id','client_secret'],'properties'=>['grant_type'=>['type'=>'string','enum'=>['client_credentials'],'default'=>'client_credentials'],'client_id'=>['type'=>'string'],'client_secret'=>['type'=>'string','format'=>'password']]]]]],'responses'=>['200'=>['description'=>'Token opaco valido por900segundos','content'=>['application/json'=>['schema'=>['type'=>'object','required'=>['access_token','token_type','expires_in'],'properties'=>['access_token'=>['type'=>'string','pattern'=>'^[a-f0-9]{64}$'],'token_type'=>['type'=>'string','enum'=>['Bearer']],'expires_in'=>['type'=>'integer','enum'=>[900]]]]]]],...$errors]]],
        '/api/query.php'=>['post'=>['tags'=>['Consultas salvas'],'operationId'=>'executarConsultaSalva','summary'=>'Executar uma das '.count($catalog).' consultas salvas','description'=>'Escolha a consulta no seletor de exemplos e altere os filtros antes de clicar Execute. O token deve autorizar exatamente o code solicitado. Referencia significa cod-refer. page(1..1000000) e pageSize(1..1000) sao opcionais na raiz do JSON. Use hasMore para avancar page; sem total ou snapshot. Mantenha filtros e pageSize ao navegar. Dados podem mudar entre requisicoes. Para desativar paginacao use paginate:false; retorna pageSize:null e hasMore:false. Cursor: escolha exemplo com sufixo cursor; copie nextCursor para cursor e mantenha filtros/pageSize. Sem page ou paginate:false. Permissao atual e token valido exigidos em cada chamada; cursor assinado expira em900s e e vinculado ao consumidor, credencial, consulta, definicao e filtros. A ordenacao recebe chaves unicas para desempate, semROWID e sem descarte de offset. Nao e snapshot. Distinct/group/aggregate/LEFT nao suportados.','security'=>[['consumerToken'=>[]]],'requestBody'=>['required'=>true,'content'=>['application/json'=>['schema'=>['oneOf'=>$oneOf,'discriminator'=>['propertyName'=>'code']],'examples'=>$examples]]],'responses'=>['200'=>['description'=>'Resultado JSON do motor, incluindo dados e metadados/paginacao quando retornados. Os campos dependem da consulta.','content'=>['application/json'=>['schema'=>['type'=>'object','required'=>['success'],'properties'=>['success'=>['type'=>'boolean'],'page'=>['type'=>'integer','nullable'=>true],'nextCursor'=>['type'=>'string','nullable'=>true],'cursorExpiresIn'=>['type'=>'integer','enum'=>[900]],'paginationMode'=>['type'=>'string','enum'=>['offset','cursor']],'pageSize'=>['type'=>'integer','nullable'=>true],'paginate'=>['type'=>'boolean'],'recordsReturned'=>['type'=>'integer'],'hasMore'=>['type'=>'boolean'],'data'=>['type'=>'array','items'=>['type'=>'object','additionalProperties'=>true]]],'additionalProperties'=>true]]]],...$errors]]]
    ],'components'=>['securitySchemes'=>['consumerToken'=>['type'=>'apiKey','in'=>'header','name'=>'X-Sursum-Query-Token','description'=>'Informe apenas o token, sem prefixo Bearer. O adaptador usa este cabecalho.']],'schemas'=>$schemas]];
    foreach($catalog as $query){
        $body=queryApiExample($query);$body['execution']='async';if($query['parallel']!==null){$body['paginate']=false;$body['webhookDelivery']='manifest';}
        $spec['paths']['/api/query.php']['post']['requestBody']['content']['application/json']['examples'][$query['code'].'-async']=['summary'=>$query['name'].' — assincrono','value'=>$body];
        $spec['components']['schemas'][$query['code']]['properties']['execution']=['type'=>'string','enum'=>['sync','async'],'default'=>'sync','description'=>'async enfileira e retorna202/jobId. Nao combina com cursor. Uma pagina ou conjunto completo se paginate:false.'];
    }
    $jobSchema=['type'=>'object','required'=>['success','jobId','status'],'properties'=>['success'=>['type'=>'boolean'],'execution'=>['type'=>'string','enum'=>['async']],'jobId'=>['type'=>'string'],'code'=>['type'=>'string'],'status'=>['type'=>'string','enum'=>['queued','parallel','consolidating','running','completed','failed','cancelled']],'resultAvailable'=>['type'=>'boolean'],'resultFormat'=>['type'=>'string','enum'=>['ndjson+gzip']],'statusUrl'=>['type'=>'string'],'resultUrl'=>['type'=>'string'],'parallel'=>['type'=>'object','properties'=>['enabled'=>['type'=>'boolean'],'totalPartitions'=>['type'=>'integer'],'completedPartitions'=>['type'=>'integer'],'runningPartitions'=>['type'=>'integer'],'failedPartitions'=>['type'=>'integer'],'maxWorkers'=>['type'=>'integer','maximum'=>10],'lastFailureCode'=>['type'=>'string','enum'=>['PARALLEL_PARTITION_RECORD_LIMIT','PARALLEL_PARTITION_BYTE_LIMIT','PARALLEL_PARTITION_LIMIT_CONFIG_INVALID'],'description'=>'Causa sanitizada da ultima particao que atingiu limite.']],],'resultExpiresAtEpoch'=>['type'=>'integer','format'=>'int64']],'additionalProperties'=>true];
    $spec['info']['version']='1.3.0';$spec['tags'][]=['name'=>'Jobs'];
    $spec['paths']['/api/query.php']['post']['responses']['202']=['description'=>'Job persistido; use jobId nas rotas autenticadas de acompanhamento/download. Worker dedicado verifica permissao antes de executar.','content'=>['application/json'=>['schema'=>$jobSchema]]];
    foreach($catalog as $query)if($query['parallel']!==null){$p=$query['parallel'];$spec['paths']['/api/query.php']['post']['description'].=' Para processamento assincrono envie execution:async (sem cursor). Retorna202. A consulta '.$query['code'].', quando paginate:false e os filtros de quebra configurados sao informados, usa particoes privadas e consolida em NDJSON gzip. Nao e snapshot transacional. O download exige o mesmo consumidor/permissao atual; manifest e full sao modos opcionais de webhook. Limites da definicao: '.$p['maxPartitions'].' particoes, '.$p['maxWorkers'].' workers, '.$p['maxPartitionRecords'].' registros e '.$p['maxPartitionBytes'].' bytes por particao, '.$p['maxResultBytes'].' bytes por exportacao e24h de retencao. Se uma particao atingir qualquer teto, o job falha sem entregar exportacao parcial; ajuste a quebra no JSON da consulta. Consultas comuns mantem o limite64MiB.';}
    foreach(['jobs'=>false,'job-result'=>true] as $route=>$download){
        $spec['paths']['/api/'.$route.'.php']=['get'=>['tags'=>['Jobs'],'operationId'=>$download?'baixarResultadoJob':'acompanharJob','summary'=>$download?'Baixar resultado':'Consultar situacao do job','description'=>'Somente o consumidor que criou o job, com token valido e permissao atual para a consulta. Outro consumidor/job inexistente retorna404. Novo token do mesmo consumidor continua acesso. Download pendente409; expirado410. Nenhum caminho interno ou plano e publicado.','security'=>[['consumerToken'=>[]]],'parameters'=>[['name'=>'jobId','in'=>'query','required'=>true,'schema'=>['type'=>'string','pattern'=>'^JOB-[0-9]{8}-[0-9]{6}-[0-9]{6}$']]],'responses'=>['200'=>['description'=>$download?'Jobs comuns retornam JSON; exportacoes paralelas retornam attachment NDJSON gzip.':'Estado atual do job.','content'=>$download?['application/json'=>['schema'=>['type'=>'object','required'=>['success'],'additionalProperties'=>true]],'application/x-ndjson'=>['schema'=>['type'=>'string','format'=>'binary']]]:['application/json'=>['schema'=>$jobSchema]]],'404'=>['description'=>'Job nao encontrado ou de outro consumidor'],'409'=>['description'=>'Resultado ainda nao disponivel'],'410'=>['description'=>'Resultado expirado'],...$errors]]];
    }
    $spec['info']['version']='1.4.0';$spec['tags'][]=['name'=>'Webhooks'];
    $webhookCode='saldo-estoque-por-referencia';
    $webhookGet=['name'=>'code','in'=>'query','required'=>true,'schema'=>['type'=>'string','example'=>$webhookCode],'description'=>'Codigo de consulta autorizado para o consumidor.'];
    $webhookPut=['type'=>'object','additionalProperties'=>false,'required'=>['code','url'],'properties'=>['code'=>['type'=>'string','example'=>$webhookCode],'url'=>['type'=>'string','format'=>'uri','example'=>'https://integracao.example.com/webhooks/sursum-estoque']]];
    $webhookDelete=['type'=>'object','additionalProperties'=>false,'required'=>['code'],'properties'=>['code'=>['type'=>'string','example'=>$webhookCode]]];
    $webhookState=['type'=>'object','required'=>['success','code','url','version','active'],'properties'=>['success'=>['type'=>'boolean'],'code'=>['type'=>'string'],'url'=>['type'=>'string'],'version'=>['type'=>'integer'],'active'=>['type'=>'boolean']]];
    $webhookPutResponse=['description'=>'Configuracao salva; webhook_secret aparece apenas nesta resposta.','content'=>['application/json'=>['schema'=>['allOf'=>[$webhookState,['type'=>'object','required'=>['webhook_secret'],'properties'=>['webhook_secret'=>['type'=>'string','format'=>'password']]]]]]]];
    $webhookGetOperation=['tags'=>['Webhooks'],'operationId'=>'consultarWebhook','summary'=>'Consultar o webhook da propria aplicacao e consulta','description'=>'A configuracao e identificada pelo consumidor autenticado e code. Nunca retorna webhook_secret. O consumidor precisa ter permissao atual para o codigo.','security'=>[['consumerToken'=>[]]],'parameters'=>[$webhookGet],'responses'=>['200'=>['description'=>'Configuracao atual.','content'=>['application/json'=>['schema'=>$webhookState]]],'404'=>['description'=>'Webhook nao cadastrado']]+$errors];
    $webhookPutOperation=[
        'tags'=>['Webhooks'],'operationId'=>'configurarWebhook','summary'=>'Cadastrar ou rotacionar o webhook da propria aplicacao e consulta','description'=>'Aceita somente URL HTTPS na porta 443. A resposta devolve webhook_secret uma vez; guarde-a para validar HMAC-SHA-256 de timestamp.raw-body. Uma nova configuracao invalida pendencias da versao anterior.','security'=>[['consumerToken'=>[]]],
        'requestBody'=>['required'=>true,'content'=>['application/json'=>['schema'=>$webhookPut]]],
        'responses'=>['200'=>$webhookPutResponse]+$errors
    ];
    $webhookDeleteOperation=[
        'tags'=>['Webhooks'],'operationId'=>'removerWebhook','summary'=>'Remover o webhook da propria aplicacao e consulta','security'=>[['consumerToken'=>[]]],
        'requestBody'=>['required'=>true,'content'=>['application/json'=>['schema'=>$webhookDelete]]],
        'responses'=>['204'=>['description'=>'Webhook removido.'],'404'=>['description'=>'Webhook nao cadastrado']]+$errors
    ];
    $spec['paths']['/api/webhook.php']=['get'=>$webhookGetOperation,'put'=>$webhookPutOperation,'delete'=>$webhookDeleteOperation];
    return $spec;

}

function queryApiPostman(array $catalog):array
{
    $save=<<<'JS'
pm.test('Token emitido', function () { pm.response.to.have.status(200); });
if (pm.response.code === 200) {
  const data = pm.response.json();
  if (!/^[a-f0-9]{64}$/.test(data.access_token) || data.expires_in !== 900) throw new Error('Resposta de token invalida');
  pm.collectionVariables.set('access_token', data.access_token);
  pm.collectionVariables.set('expires_at', Date.now() + 870000);
  pm.collectionVariables.set('cached_client_id', pm.variables.get('client_id'));
}
JS;
    $renew=<<<'JS'
const base = 'https://iol.imatextil.com.br/query-progress';
const id = pm.variables.get('client_id');
const token = pm.collectionVariables.get('access_token');
function applyToken(value) { pm.request.headers.upsert({key:'X-Sursum-Query-Token',value:value}); }
if (token && Number(pm.collectionVariables.get('expires_at')) > Date.now() && pm.collectionVariables.get('cached_client_id') === id) {
  applyToken(token);
} else {
  const secret = pm.variables.get('client_secret');
  if (!id || !secret) { pm.execution.skipRequest(); throw new Error('Preencha client_id e client_secret no ambiente local do Postman'); }
  pm.sendRequest({url:base+'/api/token.php',method:'POST',header:{'Content-Type':'application/x-www-form-urlencoded'},body:{mode:'urlencoded',urlencoded:[{key:'grant_type',value:'client_credentials'},{key:'client_id',value:id},{key:'client_secret',value:secret}]}},function(error,response){
    if (error || response.code !== 200) { pm.execution.skipRequest(); throw new Error('Nao foi possivel obter token do consumidor'); }
    let data;
    try { data=response.json(); if (!/^[a-f0-9]{64}$/.test(data.access_token) || data.expires_in !== 900) throw new Error('invalid'); }
    catch (invalid) { pm.execution.skipRequest(); throw new Error('Resposta de token invalida'); }
    pm.collectionVariables.set('access_token',data.access_token);
    pm.collectionVariables.set('expires_at',Date.now()+870000);
    pm.collectionVariables.set('cached_client_id',id);
    applyToken(data.access_token);
  });
}
JS;
    $queries=[];
    foreach($catalog as $query)$queries[]=['name'=>$query['code'],'request'=>['method'=>'POST','header'=>[['key'=>'Content-Type','value'=>'application/json'],['key'=>'X-Sursum-Query-Token','value'=>'{{access_token}}']],'url'=>QUERY_API_BASE.'/api/query.php','description'=>$query['name'].'. Exige permissao para '.$query['code'].'. Altere os filtros no Body; valores de container sao exemplos a preencher.','body'=>['mode'=>'raw','raw'=>json_encode(queryApiExample($query),JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR),'options'=>['raw'=>['language'=>'json']]]],'response'=>[]];
    $cursorQueries=[];$cursorVariables=[];
    foreach($catalog as $query)if($query['cursorEligible']){
        $item=null;foreach($queries as $candidate)if($candidate['name']===$query['code']){$item=$candidate;break;}
        $key='cursor_'.$query['code'];$body=queryApiExample($query);unset($body['page'],$body['paginate']);$body['paginationMode']='cursor';$body['cursor']='{{'.$key.'}}';
        $item['request']['body']['raw']=json_encode($body,JSON_PRETTY_PRINT|JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES|JSON_THROW_ON_ERROR);
        $item['request']['description'].=' Modo cursor: Send avanca automaticamente usando nextCursor. Ao terminar, limpe a variavel '.$key.' para reiniciar. Ao mudar filtros/tamanho/consumidor, limpe esta variavel. Cursor900s, semsnapshot.';
        $cursorQueries[]=$item;$cursorVariables[]=['key'=>$key,'value'=>''];
    }
    $cursorBefore=<<<'JS'
const cursorKey='cursor_'+pm.info.requestName;
if (pm.collectionVariables.get(cursorKey)==='__END__') { pm.execution.skipRequest(); throw new Error('Fim da navegacao. Limpe '+cursorKey+' para reiniciar.'); }
JS;
    $cursorAfter=<<<'JS'
if (pm.response.code===200) {
  const data=pm.response.json();
  if(data.success && data.paginationMode==='cursor') {
    pm.collectionVariables.set('cursor_'+pm.info.requestName,data.hasMore?data.nextCursor:'__END__');
    pm.test('Continuacao de cursor consistente',function(){pm.expect(data.hasMore?typeof data.nextCursor==='string':data.nextCursor===null).to.eql(true);});
  }
}
JS;

    $asyncQueries=[];
    foreach($queries as $item){$body=json_decode($item['request']['body']['raw'],true,32,JSON_THROW_ON_ERROR);$body['execution']='async';foreach($catalog as $query)if($query['code']===$item['name']&&$query['parallel']!==null){$body['paginate']=false;$body['webhookDelivery']='manifest';$p=$query['parallel'];$item['request']['description'].=' Exportacao paralela por data: '.$p['maxWorkers'].' workers, '.$p['maxPartitions'].' particoes, '.$p['maxPartitionRecords'].' registros e '.$p['maxPartitionBytes'].' bytes por particao; se uma particao atingir o teto, o job falha sem truncamento.';} $item['request']['body']['raw']=json_encode($body,JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE|JSON_THROW_ON_ERROR);$asyncQueries[]=$item;}
    foreach(['jobs'=>false,'job-result'=>true] as $route=>$download)$asyncQueries[]=['name'=>$download?'Baixar resultado':'Acompanhar job','request'=>['method'=>'GET','header'=>[['key'=>'X-Sursum-Query-Token','value'=>'{{access_token}}']],'url'=>QUERY_API_BASE.'/api/'.$route.'.php?jobId={{job_id}}','description'=>'Usa job_id salvo pelo envio assincrono anterior. Repita acompanhamento ate completed; depois baixe. Token e permissao atual sempre exigidos.'],'response'=>[]];
    $asyncAfter=<<<'JS'
if(pm.response.code===202){const data=pm.response.json();if(!data.success||!/^JOB-[0-9]{8}-[0-9]{6}-[0-9]{6}$/.test(data.jobId))throw new Error('Job invalido');pm.collectionVariables.set('job_id',data.jobId);}
JS;
    $webhookHeaders=[['key'=>'Content-Type','value'=>'application/json'],['key'=>'X-Sursum-Query-Token','value'=>'{{access_token}}']];
    $webhookItems=[
        ['name'=>'Consultar webhook','request'=>['method'=>'GET','header'=>[['key'=>'X-Sursum-Query-Token','value'=>'{{access_token}}']],'url'=>QUERY_API_BASE.'/api/webhook.php?code=saldo-estoque-por-referencia'],'response'=>[]],
        ['name'=>'Cadastrar ou rotacionar webhook','request'=>['method'=>'PUT','header'=>$webhookHeaders,'url'=>QUERY_API_BASE.'/api/webhook.php','body'=>['mode'=>'raw','raw'=>json_encode(['code'=>'saldo-estoque-por-referencia','url'=>'https://integracao.example.com/webhooks/sursum-estoque'],JSON_PRETTY_PRINT),'options'=>['raw'=>['language'=>'json']]]],'response'=>[]],
        ['name'=>'Remover webhook','request'=>['method'=>'DELETE','header'=>$webhookHeaders,'url'=>QUERY_API_BASE.'/api/webhook.php','body'=>['mode'=>'raw','raw'=>json_encode(['code'=>'saldo-estoque-por-referencia'],JSON_PRETTY_PRINT),'options'=>['raw'=>['language'=>'json']]]],'response'=>[]]
    ];
    return ['info'=>['name'=>'Sursum MED — consultas salvas','description'=>'Configure client_id/client_secret no ambiente local do Postman. Colecao sem credenciais exportadas. Consultas renovam tokens automaticamente com margem de30s. Permissoes e autorizacao permanecem no PASOE. Ao rotacionar segredo, execute Obter token para substituir o cache. Nao compartilhe exportacoes com segredos preenchidos.','schema'=>'https://schema.getpostman.com/json/collection/v2.1.0/collection.json'],'variable'=>[['key'=>'client_id','value'=>''],['key'=>'client_secret','value'=>''],['key'=>'access_token','value'=>''],['key'=>'expires_at','value'=>'0'],['key'=>'cached_client_id','value'=>''],['key'=>'job_id','value'=>''],...$cursorVariables],'item'=>[
        ['name'=>'Autenticacao','item'=>[['name'=>'Obter token','request'=>['method'=>'POST','header'=>[['key'=>'Content-Type','value'=>'application/x-www-form-urlencoded']],'url'=>QUERY_API_BASE.'/api/token.php','body'=>['mode'=>'urlencoded','urlencoded'=>[['key'=>'grant_type','value'=>'client_credentials'],['key'=>'client_id','value'=>'{{client_id}}'],['key'=>'client_secret','value'=>'{{client_secret}}']]]],'event'=>[['listen'=>'test','script'=>['type'=>'text/javascript','exec'=>explode("\n",$save)]]]]]],
        ['name'=>'Consultas','event'=>[['listen'=>'prerequest','script'=>['type'=>'text/javascript','exec'=>explode("\n",$renew)]]],'item'=>$queries],
        ['name'=>'Consultas por cursor','event'=>[['listen'=>'prerequest','script'=>['type'=>'text/javascript','exec'=>explode("\n",$cursorBefore."\n".$renew)]],['listen'=>'test','script'=>['type'=>'text/javascript','exec'=>explode("\n",$cursorAfter)]]],'item'=>$cursorQueries],
        ['name'=>'Consultas assincronas','event'=>[['listen'=>'prerequest','script'=>['type'=>'text/javascript','exec'=>explode("\n",$renew)]],['listen'=>'test','script'=>['type'=>'text/javascript','exec'=>explode("\n",$asyncAfter)]]],'item'=>$asyncQueries],
        ['name'=>'Webhooks','description'=>'Cada consumidor configura somente o destino de cada consulta autorizada. O segredo aparece uma unica vez ao cadastrar/rotacionar; valide HMAC-SHA-256 de timestamp.raw-body e deduplique por X-Sursum-Webhook-Id.','event'=>[['listen'=>'prerequest','script'=>['type'=>'text/javascript','exec'=>explode("\n",$renew)]]],'item'=>$webhookItems]
    ]];
}
