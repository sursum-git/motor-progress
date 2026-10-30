#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const identifier=value=>typeof value==='string'&&/^[A-Za-z0-9_.-]{1,128}$/.test(value)&&value!=='.'&&value!=='..';
function validate(cfg){
 if(!cfg||cfg.version!==1||!Array.isArray(cfg.consumers)||cfg.consumers.length>1000)throw Error('Configuracao invalida.');
 const ids=new Set(),hashes=new Set();
 for(const c of cfg.consumers){
  if(!identifier(c.id)||typeof c.active!=='boolean'||!['admin','consumer'].includes(c.role)||!Number.isSafeInteger(c.expiresAtEpoch)||c.expiresAtEpoch<=0||typeof c.tokenSha256!=='string'||!/^[a-fA-F0-9]{64}$/.test(c.tokenSha256)||!Array.isArray(c.queries)||c.queries.length>1000||!c.queries.every(identifier)||new Set(c.queries).size!==c.queries.length||ids.has(c.id)||hashes.has(c.tokenSha256.toLowerCase()))throw Error('Configuracao invalida.');
  ids.add(c.id);hashes.add(c.tokenSha256.toLowerCase());
  if(Object.hasOwn(c,'clientSecretSha256')&&(c.role!=='consumer'||typeof c.clientSecretSha256!=='string'||!/^[a-f0-9]{64}$/.test(c.clientSecretSha256)))throw Error('Configuracao invalida.');
 }
 return cfg;
}
function read(file,initial=false){
 if(!fs.existsSync(file)){if(initial)return {version:1,consumers:[]};throw Error('Configuracao inexistente.');}
 const stat=fs.lstatSync(file);if(!stat.isFile()||stat.isSymbolicLink()||stat.size>1048576)throw Error('Arquivo de configuracao invalido.');
 return validate(JSON.parse(fs.readFileSync(file,'utf8')));
}
function options(args){const out={};for(let i=0;i<args.length;i+=2){if(!['--id','--queries','--role','--days'].includes(args[i])||args[i+1]===undefined||Object.hasOwn(out,args[i].slice(2)))throw Error('Parametros invalidos.');out[args[i].slice(2)]=args[i+1];}return out;}
function main(args){
 const [given,command,...tail]=args;if(!given||!['create','rotate','revoke','list'].includes(command))throw Error('Uso: node query-consumers.cjs <arquivo-absoluto> create|rotate|revoke|list [--id ID] [--queries codigo,...] [--role consumer|admin] [--days 90]');
 if(!path.isAbsolute(given))throw Error('Informe um caminho absoluto fora da raiz web.');
 const file=path.resolve(given),opts=options(tail);
 if(command==='list'){const cfg=read(file);process.stdout.write(JSON.stringify(cfg.consumers.map(({tokenSha256,clientSecretSha256,...c})=>({...c,clientCredentials:!!clientSecretSha256})),null,2)+'\n');return;}
 if(!identifier(opts.id))throw Error('Identificador invalido.');
 const role=opts.role||'consumer',queries=(opts.queries||'').split(',').filter(Boolean);
 const daysText=opts.days||'90',days=Number(daysText);
 if(!/^\d+$/.test(daysText)||!Number.isSafeInteger(days)||days<1||days>365)throw Error('Validade deve ser de 1 a 365 dias.');
 if(command==='create'&&(!['admin','consumer'].includes(role)||!queries.every(identifier)||(role==='consumer'&&!queries.length)))throw Error('Perfil e permissoes explicitas obrigatorios.');
 if(command!=='create'&&(opts.role||opts.queries))throw Error('Rotacao/revogacao preserva as permissoes existentes.');
 const lock=file+'.lock';let lockFd,tmp;
 try{
  lockFd=fs.openSync(lock,'wx',0o600);
  const cfg=read(file,command==='create');let c=cfg.consumers.find(c=>c.id===opts.id),token;
  if(command==='create'){if(c)throw Error('Consumidor ja cadastrado.');c={id:opts.id,role,queries,active:true};cfg.consumers.push(c);}
  else if(!c)throw Error('Consumidor inexistente.');
  if(command==='revoke')c.active=false;
  else{token=crypto.randomBytes(32).toString('hex');c.tokenSha256=crypto.createHash('sha256').update(token).digest('hex');delete c.clientSecretSha256;c.expiresAtEpoch=Math.floor(Date.now()/1000)+days*86400;c.active=true;}
  validate(cfg);
  tmp=file+'.'+crypto.randomBytes(8).toString('hex')+'.tmp';
  const fd=fs.openSync(tmp,'wx',0o600);try{fs.writeFileSync(fd,JSON.stringify(cfg,null,2)+'\n');fs.fsyncSync(fd);}finally{fs.closeSync(fd);}
  fs.renameSync(tmp,file);tmp=undefined;
  process.stdout.write(JSON.stringify({id:c.id,active:c.active,expiresAtEpoch:c.expiresAtEpoch,...(token?{token}:{}),notice:token?'Guarde o token em cofre; esta e a unica exibicao.':'Consumidor revogado.'})+'\n');
 }finally{if(tmp)fs.rmSync(tmp,{force:true});if(lockFd!==undefined){fs.closeSync(lockFd);fs.unlinkSync(lock);}}
}
if(require.main===module){try{main(process.argv.slice(2));}catch(error){process.stderr.write((error.code==='EEXIST'?'Outra operacao esta em andamento.':error.code?'Falha ao acessar a configuracao.':error.message)+'\n');process.exitCode=1;}}
module.exports={validate,main};
