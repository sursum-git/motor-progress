const { test, expect, request } = require('@playwright/test');
const base = (process.env.SURSUM_JSON_PROGRAM_BASE_URL || '').replace(/\/+$/, '');
const route = '/SursumPrograms/consulta-pedidos-venda';
const filters = { dtImplantIni: '2026-04-01', dtImplantFim: '2026-09-24', nrPedidoIni: 252711, nrPedidoFim: 252711 };
test.describe('Demais setters da BO via PASOE', () => {
 test.skip(!base, 'Informe o endpoint PASOE');
 let api;
 test.beforeAll(async () => {
  api = await request.newContext({ignoreHTTPSErrors:true, timeout:180000});
  const response = await api.post(base+route, {data:{dtImplantIni:filters.dtImplantIni,dtImplantFim:filters.dtImplantFim}});
  expect(response.status()).toBe(200);
  const data=await response.json();expect(data.success).toBe(true);expect(data.total).toBeGreaterThan(0);
  const row=data['tt-dados'].find(r=>r['nome-repres'] && r['cod-estabel']);expect(row).toBeTruthy();
  filters.nrPedidoIni=row['nr-pedido'];filters.nrPedidoFim=row['nr-pedido'];
 });
 test.afterAll(async () => { if(api) await api.dispose(); });
 async function call(extra) {
  const response = await api.post(base+route,{data:{...filters,...extra}});
  expect(response.status()).toBe(200);
  return response.json();
 }
 for(const [name,data,word] of [
  ['estabelecimento incompleto',{estabIni:'001'},'juntos'],
  ['cliente incompleto',{clienteFim:10},'juntos'],
  ['representante incompleto',{represIni:'A'},'juntos'],
  ['cliente invertido',{clienteIni:20,clienteFim:10},'menor'],
  ['estabelecimento invertido',{estabIni:'999',estabFim:'001'},'menor'],
  ['representante invertido',{represIni:'Z',represFim:'A'},'menor'],
  ['clube exige booleano',{somenteClubeIma:'false'},'somenteClubeIma'],
  ['bloqueio invalido',{bloqueioAprov:'SIM'},'bloqueioAprov'],
  ['situacao malformada',{sitPed:'1,,2'},'sitPed'],
  ['preco invalido',{sitPreco:'x'},'sitPreco'],
  ['avaliacao nula',{sitAval:null},'sitAval'],
  ['estabelecimento exige texto',{estabIni:1,estabFim:2},'estabIni'],
  ['cliente fracionario',{clienteIni:1.5,clienteFim:2},'clienteIni']
 ]) test(name,async()=>{
  const json=await call(data);expect(json.success).toBe(false);expect(json.error).toContain(word);expect(json['tt-dados']).toEqual([]);
 });
 test('filtros de estabelecimento cliente representante pedido e avaliacao',async()=>{
  const original=await call({});expect(original.success).toBe(true);expect(original.total).toBeGreaterThan(0);
  const row=original['tt-dados'][0];
  for(const [extra,field] of [
   [{estabIni:row['cod-estabel'],estabFim:row['cod-estabel']},'cod-estabel'],
   [{clienteIni:row['cod-emitente'],clienteFim:row['cod-emitente']},'cod-emitente'],
   [{represIni:row['nome-repres'],represFim:row['nome-repres']},'nome-repres'],
   [{sitPed:String(row['cod-sit-ped'])},'cod-sit-ped'],
   [{sitPed:' 0'+row['cod-sit-ped']+', '+row['cod-sit-ped']+' '},'cod-sit-ped'],
   [{sitAval:String(row['cod-sit-aval'])},'cod-sit-aval']
  ]) {
   const result=await call(extra);expect(result.success).toBe(true);
   const expected=original['tt-dados'].filter(r=>r[field]===row[field]);expect(result['tt-dados']).toEqual(expected);
  }
  for(const extra of [{estabIni:'!INEXISTENTE!',estabFim:'!INEXISTENTE!'},{clienteIni:2147483647,clienteFim:2147483647},{represIni:'!INEXISTENTE!',represFim:'!INEXISTENTE!'},{sitPed:'999'},{sitAval:'999'},{sitPreco:'999'}]) {
   const result=await call(extra);expect(result.success).toBe(true);expect(result.total).toBe(0);
  }
 });
 test('bloqueios e preco particionam a consulta; clube false preserva o conjunto',async()=>{
  const original=await call({});expect(original.success).toBe(true);expect(original.total).toBeGreaterThan(0);
  const normalize=rows=>rows.map(r=>JSON.stringify(r)).sort();
  const yes=await call({bloqueioAprov:'YES'}),no=await call({bloqueioAprov:'NO'});
  expect(yes.success).toBe(true);expect(no.success).toBe(true);
  expect(normalize([...yes['tt-dados'],...no['tt-dados']])).toEqual(normalize(original['tt-dados']));
  const all=await call({bloqueioAprov:' yes, no ',somenteClubeIma:false});expect(all.success).toBe(true);
  expect(normalize(all['tt-dados'])).toEqual(normalize(original['tt-dados']));
  const a=await call({sitPreco:'1,2,3'}),b=await call({sitPreco:'4,5,6'});expect(a.success).toBe(true);expect(b.success).toBe(true);
  expect(normalize([...a['tt-dados'],...b['tt-dados']])).toEqual(normalize(original['tt-dados']));
  const clube=await call({somenteClubeIma:true});expect(clube.success).toBe(true);
  for(const row of normalize(clube['tt-dados'])) expect(normalize(original['tt-dados'])).toContain(row);
 });
});
