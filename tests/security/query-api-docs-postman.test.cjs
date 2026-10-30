const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const collection = JSON.parse(fs.readFileSync(path.join(__dirname, '../../docs/api/sursum-med-postman.collection.json'), 'utf8'));
const script = collection.item[1].event[0].script.exec.join('\n');
const token = 'a'.repeat(64);
let checks = 0;
function run({cache = {}, id = 'example-client', secret = 'dummy-secret', code = 200, malformed = false} = {}) {
  const values = {client_id: id, client_secret: secret, baseUrl: 'https://untrusted.invalid'};
  const calls = [], headers = [];
  let skipped = false;
  const pm = {
    variables: {get: key => values[key]},
    collectionVariables: {get: key => cache[key], set: (key, value) => { cache[key] = value; }},
    request: {headers: {upsert: header => headers.push(header)}},
    execution: {skipRequest: () => { skipped = true; }},
    sendRequest: (request, callback) => {
      calls.push(request);
      callback(null, {code, json: () => { if (malformed) throw Error('bad JSON'); return {access_token: token, expires_in: 900}; }});
    }
  };
  let error;
  try { vm.runInNewContext(script, {pm, Date}); } catch (caught) { error = caught; }
  return {calls, headers, cache, skipped, error};
}
let result = run();
assert.equal(result.calls[0].url, 'https://iol.imatextil.com.br/query-progress/api/token.php');
assert.equal(result.headers[0].value, token); checks++;
result = run({cache: result.cache});
assert.equal(result.calls.length, 0); assert.equal(result.headers[0].value, token); checks++;
result = run({cache: {access_token: token, expires_at: Date.now() - 1, cached_client_id: 'example-client'}});
assert.equal(result.calls.length, 1); checks++;
result = run({cache: {access_token: token, expires_at: Date.now() + 900000, cached_client_id: 'other-client'}});
assert.equal(result.calls.length, 1); checks++;
for (const options of [{secret: ''}, {code: 401}, {malformed: true}]) {
  result = run(options); assert(result.skipped && result.error); assert.equal(result.headers.length, 0); checks++;
}
for (const folder of collection.item) for (const item of folder.item) {
  assert.match(item.request.url, /^https:\/\/iol\.imatextil\.com\.br\/query-progress\/api\/(?:(token|query)\.php|(jobs|job-result)\.php\?jobId=\{\{job_id\}\})$/);
}
checks++;
const cursorFolder=collection.item[2];
const cursorCache={},cursorPm={info:{requestName:'sample'},collectionVariables:{get:k=>cursorCache[k],set:(k,v)=>cursorCache[k]=v},response:{code:200,json:()=>({success:true,paginationMode:'cursor',hasMore:true,nextCursor:'next'})},test:(_,fn)=>fn(),expect:v=>({to:{eql:expected=>assert.equal(v,expected)}})};
const after=cursorFolder.event.find(x=>x.listen==='test').script.exec.join('\n');
vm.runInNewContext(after,{pm:cursorPm});assert.equal(cursorCache.cursor_sample,'next');checks++;
cursorPm.response.json=()=>({success:true,paginationMode:'cursor',hasMore:false,nextCursor:null});
vm.runInNewContext(after,{pm:cursorPm});assert.equal(cursorCache.cursor_sample,'__END__');checks++;
let cursorSkipped=false;cursorPm.execution={skipRequest:()=>cursorSkipped=true};
assert.throws(()=>vm.runInNewContext(cursorFolder.event.find(x=>x.listen==='prerequest').script.exec.join('\n'),{pm:cursorPm,Date}),/Fim da navegacao/);assert(cursorSkipped);checks++;
console.log('PASS ' + checks + ' Postman authentication, cursor and destination checks');
const asyncFolder=collection.item[3],asyncCache={};
const asyncPost=asyncFolder.event.find(x=>x.listen==='test').script.exec.join('\n');
const asyncPm={collectionVariables:{set:(k,v)=>asyncCache[k]=v},response:{code:202,json:()=>({success:true,jobId:'JOB-20261028-123456-123456'})}};
vm.runInNewContext(asyncPost,{pm:asyncPm});assert.equal(asyncCache.job_id,'JOB-20261028-123456-123456');
asyncPm.response.json=()=>({success:true,jobId:'../../private'});assert.throws(()=>vm.runInNewContext(asyncPost,{pm:asyncPm}),/Job invalido/);
asyncPm.response.code=400;asyncCache.job_id='previous';vm.runInNewContext(asyncPost,{pm:asyncPm});assert.equal(asyncCache.job_id,'previous');
console.log('PASS 3 Postman asynchronous job capture checks');
