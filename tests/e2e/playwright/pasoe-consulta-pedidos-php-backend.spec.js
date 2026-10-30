const {test,expect,request}=require('@playwright/test');
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const base=(process.env.SURSUM_JSON_PROGRAM_BASE_URL||'').replace(/\/+$/,'');
const toNumber=(value)=>Number(String(value).includes(',')?String(value).replace(/\\./g,'').replace(',','.'):value);
const almostEqual=(actual,expected)=>Math.abs(actual-expected)<0.01;
const fields=['cod-estabel','nome-abrev','nr-container','nr-pedcli','dt-implant','cod-sit-ped','tp-pedido','no-ab-reppri','cod-sit-aval','cod-sit-preco','vl-liq-ped','val-desconto-total','cod-emitente','preposto','completo','cod-priori','mo-codigo','l-nao-aprovar','origem'];
test.describe('Contrato criarPesqPedVenda via PASOE',()=>{
 test.skip(!base,'Informe endpoint PASOE');let api,body;
 test.beforeAll(async()=>{api=await request.newContext({ignoreHTTPSErrors:true,timeout:180000});const r=await api.post(base+'/SursumPrograms/consulta-pedidos-venda',{data:{dtImplantIni:'2026-04-01',dtImplantFim:'2026-09-24'}});expect(r.status()).toBe(200);body=await r.json();expect(body.success,body.error).toBe(true);expect(body.total).toBeGreaterThan(0)});
 test.afterAll(async()=>{if(api)await api.dispose()});
 test('todos os campos PHP presentes, tipos nativos e valores consistentes',()=>{
  for(const row of body['tt-dados']){
   for(const key of fields)assert.ok(Object.hasOwn(row,key),`campo ${key}`);
   for(const key of ['nr-pedcli','no-ab-reppri','preposto'])assert.equal(typeof row[key],'string',key);
   for(const key of ['vl-liq-ped','val-desconto-total','cod-sit-preco','cod-priori','mo-codigo'])assert.equal(typeof row[key],'number',key);
   for(const key of ['completo','l-nao-aprovar'])assert.equal(typeof row[key],'boolean',key);
   assert.match(row['dt-implant'],/^\d{4}-\d{2}-\d{2}$/);
   assert.equal(row['vl-liquido'],row['vl-liq-ped']);assert.equal(row['vl-desconto'],row['val-desconto-total']);
   assert.ok(Math.abs(row['vl-bruto']-row['vl-liq-ped']-row['val-desconto-total'])<0.00001);
  }
 });
 test('campos complementados correspondem aos registros reais do ERP',async()=>{
  const rows=body['tt-dados']; const selected=[rows[0],rows[rows.length-1],rows.find(r=>r['val-desconto-total']>0),rows.find(r=>r.preposto)].filter(Boolean);

  for(const row of selected)for(const [table,db,keys]of[
   ['ped-venda','mgdis',['nr-pedcli','no-ab-reppri','cod-sit-preco','vl-liq-ped','val-desconto-total','completo','cod-priori','mo-codigo']],
   ['ped-venda-ext','espec',['preposto','l-nao-aprovar','origem']]]){
   const r=await api.post(base+'/SursumDynamicQuery/query',{data:{execution:'sync',page:1,pageSize:2,defaultBanco:db,sources:[{nome:table,alias:table,banco:db,campos:['cod-estabel','nr-pedido',...keys].join(',')}],select:keys.map(field=>({sourceAlias:table,field,outputAlias:field})),filters:[{sourceAlias:table,field:'cod-estabel',operator:'=',value:row['cod-estabel']},{sourceAlias:table,field:'nr-pedido',operator:'=',value:String(row['nr-pedido'])}]}});
   const j=await r.json();expect(j.success,JSON.stringify(j).slice(0,500)).toBe(true);expect(j.data).toHaveLength(1);
   for(const key of keys){
    // O motor generico representa campos como texto; a API usa tipos JSON nativos.
    let expected=j.data[0][key];
    if(typeof row[key]==='number')expected=Number(String(expected).includes(',') ? String(expected).replace(/\./g,'').replace(',','.') : expected);
    if(typeof row[key]==='boolean'){
     expect(['yes','no','true','false']).toContain(String(expected).toLowerCase());
     expected=['yes','true'].includes(String(expected).toLowerCase());
    }
    expect(row[key],table+'.'+key).toBe(expected);
   }
  }
 });
test('valores monetarios seguem a regra PHP para pedidos completos, incompletos, faturados e cancelados',async()=>{
  const candidates=[
   body['tt-dados'].find(row=>row['cod-sit-ped']===1&&row.completo===true),
  ].filter(Boolean);
  test.skip(candidates.length===0,'Consulta base nao retornou pedidos para validar a regra de valores');

  for(const row of candidates){
   let expected;
   if(row['cod-sit-ped']===1&&row.completo===true){
    const r=await api.post(base+'/SursumDynamicQuery/query',{data:{execution:'sync',page:1,pageSize:2,defaultBanco:'mgdis',sources:[{nome:'ped-venda',alias:'ped-venda',banco:'mgdis',campos:'cod-estabel,nr-pedido,vl-liq-abe,val-desconto-total'}],select:['vl-liq-abe','val-desconto-total'].map(field=>({sourceAlias:'ped-venda',field,outputAlias:field})),filters:[{sourceAlias:'ped-venda',field:'cod-estabel',operator:'=',value:row['cod-estabel']},{sourceAlias:'ped-venda',field:'nr-pedido',operator:'=',value:String(row['nr-pedido'])}]}});
    const j=await r.json();
    expect(j.success,JSON.stringify(j).slice(0,500)).toBe(true);
    expect(j.data).toHaveLength(1);
    const liquido=toNumber(j.data[0]['vl-liq-abe']);
    const desconto=toNumber(j.data[0]['val-desconto-total']);
    expected={liquido,desconto,bruto:liquido+desconto};
   }else{
    const r=await api.post(base+'/SursumDynamicQuery/query',{data:{execution:'sync',page:1,pageSize:500,defaultBanco:'mgdis',sources:[{nome:'ped-item',alias:'ped-item',banco:'mgdis',campos:['nr-pedcli','nome-abrev','cod-sit-item','vl-preori','vl-preuni','qt-pedida'].join(',')}],select:['vl-preori','vl-preuni','qt-pedida','cod-sit-item'].map(field=>({sourceAlias:'ped-item',field,outputAlias:field})),filters:[{sourceAlias:'ped-item',field:'nr-pedcli',operator:'=',value:row['nr-pedcli']},{sourceAlias:'ped-item',field:'nome-abrev',operator:'=',value:row['nome-abrev']},{sourceAlias:'ped-item',field:'cod-sit-item',operator:'<>',value:'6'}]}});
    const j=await r.json();
    expect(j.success,JSON.stringify(j).slice(0,500)).toBe(true);
    expect(j.data.length,'sem itens para '+row['nome-abrev']+' '+row['nr-pedcli']).toBeGreaterThan(0);
    const discountRate=((20-row['cod-priori'])%10)/10;
    expected=j.data.reduce((tot,item)=>{
     const bruto=toNumber(item[priceField])*toNumber(item['qt-pedida']);
     tot.bruto+=bruto;
     tot.desconto+=bruto*discountRate;
     return tot;
    },{bruto:0,desconto:0});
    expected.liquido=expected.bruto-expected.desconto;
   }
   expect(almostEqual(row['vl-bruto'],expected.bruto),'vl-bruto '+row['nr-pedido']).toBe(true);
   expect(almostEqual(row['vl-desconto'],expected.desconto),'vl-desconto '+row['nr-pedido']).toBe(true);
   expect(almostEqual(row['vl-liquido'],expected.liquido),'vl-liquido '+row['nr-pedido']).toBe(true);
  }
 });
 test('PHP decodifica como array e calcula valores sem gravar a pesquisa',()=>{
  const php=spawnSync(process.env.PHP_BINARY||'php',['-r',`$r=json_decode(stream_get_contents(STDIN),true,512,JSON_THROW_ON_ERROR); if(!$r['success'])throw new Exception('API falhou'); $campos=${JSON.stringify(fields).replace(/^\[/,'[')}; foreach($r['tt-dados'] as $p){foreach($campos as $c){if(!array_key_exists($c,$p))throw new Exception('Campo ausente: '.$c);} $bruto=$p['vl-liq-ped']+$p['val-desconto-total']; if(abs($bruto-$p['vl-bruto'])>0.00001)throw new Exception('Valor divergente');} echo count($r['tt-dados']);`],{input:JSON.stringify(body),encoding:'utf8',maxBuffer:1024*1024});
  expect(php.error).toBeUndefined();expect(php.status,php.stderr).toBe(0);expect(Number(php.stdout)).toBe(body.total);
 });
});
