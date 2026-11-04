/** Audit source UID/import policy and real isolated clean-editor stability. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { execFileSync } from 'node:child_process';
import { ROOT, parseCLI, newSandbox, copyFile, indexProject, sha256, writeJSON, gitHead, gitDirty, runCommand } from './compat-kit.ts';
const argv=process.argv.slice(2), write=argv.includes('--write-missing-uids');
const options=parseCLI(argv.filter(a=>a!=='--write-missing-uids'));
if(write && (options.engines.length!==1 || options.engines[0]!.label!=='4.7'))throw Error('Seed missing UIDs with pinned 4.7 only');
// Includes staged new task files; intentionally excludes unrelated untracked work.
const files=execFileSync('git',['ls-files','-z'],{cwd:ROOT,encoding:'utf8'}).split('\0').filter(Boolean);
const scripts=files.filter(p=>p.endsWith('.gd'));
const seen=new Map<string,string>();
for(const p of files.filter(p=>p.endsWith('.gd.uid')||p.endsWith('.import'))) {
 const text=fs.readFileSync(path.join(ROOT,p),'utf8');
 const uid=p.endsWith('.uid')?text.trim():text.match(/^uid="(uid:\/\/\w+)"$/m)?.[1];
 if(!uid || !/^uid:\/\/[a-z0-9]+$/.test(uid))throw Error('Malformed UID '+p);
 if(seen.has(uid))throw Error('Duplicate UID '+p+' / '+seen.get(uid));
 seen.set(uid,p);
 if(p.endsWith('.gd.uid')&&!files.includes(p.slice(0,-4)))throw Error('Orphan script UID '+p);
}
for(const script of scripts)if(!fs.existsSync(path.join(ROOT,script+'.uid'))&&!write)throw Error('Missing UID '+script);
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
 const sandbox=newSandbox(selection), output=path.join(options.output,selection.label);
 fs.mkdirSync(output,{recursive:true});
 fs.writeFileSync(path.join(sandbox.workspace,'_sc_'),'');
 try {
  for(const p of files)copyFile(path.join(ROOT,p),path.join(sandbox.project,p));
  // Test import metadata independently from intentional compile-before-Play output updates.
  const config=path.join(sandbox.project,'project.godot');
  fs.appendFileSync(config,'\n[editor_plugins]\nenabled=PackedStringArray()\n');
  const original=new Map(files.filter(p=>p.endsWith('.gd.uid')||p.endsWith('.import')).map(p=>[p,sha256(path.join(sandbox.project,p))]));
  const stages=[];
  const baseline=new Map(original);
  const importNormalizations:unknown[]=[];
  for(const pass of [1,2]) {
   const stage=await indexProject(sandbox,sandbox.project,path.join(output,`editor-${pass}.log`),['--audio-driver','Dummy']);
   stages.push(stage);
   if(stage.status!=='PASS') {
    // Full repository includes intentionally 4.7-only R01 research. Keep its
    // actual FAIL evidence, allow only the measured 4.0 diagnostics.
    const log=fs.readFileSync(path.join(output,`editor-${pass}.log`),'utf8');
    const errors=log.split(/\r?\n/).filter(line=>line.startsWith('SCRIPT ERROR:')||line.startsWith('ERROR:'));
    const expected=[
     'SCRIPT ERROR: Parse Error: Could not find base class "Logger".',
     'SCRIPT ERROR: Parse Error: Could not resolve script "res://tests/research/bindable/capture.gd".',
     "SCRIPT ERROR: Parse Error: Cannot infer the type of \"capture\" variable because the value doesn't have a set type.",
     'SCRIPT ERROR: Parse Error: Static function "add_logger()" not found in base "OS".',
     'SCRIPT ERROR: Parse Error: Static function "remove_logger()" not found in base "OS".',
     "SCRIPT ERROR: Parse Error: Cannot infer the type of \"diagnostics\" variable because the value doesn't have a set type."
    ];
    if(selection.label!=='4.0.4'||stage.exit_code!==0||stage.timeout||!log.includes('C01_PROJECT_INDEX_READY')||!errors.length||errors.some(e=>!expected.includes(e))||[...log.matchAll(/^SCRIPT ERROR:.*\n([^\n]*)/gm)].some(m=>!/^\s+at: GDScript::reload \(res:\/\/tests\/research\/bindable\/(capture|probe)\.gd:\d+\)$/.test(m[1]!)))throw Error('Metadata import failed: '+JSON.stringify(stage));
    stage.known_limitation='Existing R01 Logger-based research is 4.7-only; editor diagnostic result remains FAIL, metadata assertions are separate.';
    console.log('KNOWN_4_0_RESEARCH_EDITOR_FAIL '+errors.length+' diagnostics (raw log retained)');
   }
   const rewritten=[...baseline].filter(([p,hash])=>sha256(path.join(sandbox.project,p))!==hash).map(([p])=>({path:p,before:fs.readFileSync(path.join(ROOT,p),'utf8'),after:fs.readFileSync(path.join(sandbox.project,p),'utf8')}));
   if(rewritten.length) {
    writeJSON(path.join(output,'rewritten.json'),rewritten);
    const textureDefaults=['compress/uastc_level=0','compress/rdo_quality_loss=0.0','process/channel_remap/red=0','process/channel_remap/green=1','process/channel_remap/blue=2','process/channel_remap/alpha=3'];
    const fontDefaults=['disable_embedded_bitmaps=true','modulate_color_glyphs=false','keep_rounding_remainders=true'];
    const texturePaths=['Assets/Estragon Centered Logo.png.import','Assets/Estragon Centered Logo.svg.import','Assets/Estragon Horizontal Logo Black.svg.import','Assets/Estragon Horizontal Logo White.svg.import'];
    for(const change of rewritten) {
     const defaults=texturePaths.includes(change.path)?textureDefaults:change.path==='Assets/Fonts/LondonTwo.ttf.import'?fontDefaults:[];
     const expected=change.before.split('\n').filter(line=>!defaults.includes(line)).join('\n');
     if(selection.label!=='4.0.4'||pass!==1||!defaults.length||change.after!==expected)throw Error('Unexpected metadata rewrite: '+change.path);
     importNormalizations.push({path:change.path,before_sha256:original.get(change.path),after_sha256:sha256(path.join(sandbox.project,change.path)),removed_defaults:defaults});
     baseline.set(change.path,sha256(path.join(sandbox.project,change.path)));
    }
    console.log('KNOWN_4_0_ASSET_NORMALIZATION '+rewritten.length+' settings files; UIDs unchanged, second import must be stable');
   }
  }
  const identity=await runCommand([sandbox.binary,'--headless','--path',sandbox.project,'--script','res://tests/adapter_proof/metadata.gd'],sandbox.workspace,sandbox.env,path.join(output,'identity.log'),'GODOT_METADATA_IDENTITY_OK',{abortOnError:true});
  stages.push(identity);
  if(identity.status!=='PASS')throw Error('Metadata identity/import failed: '+JSON.stringify(identity));
  const allowed=new Set(files);
  const unexpected:string[]=[];
  function scan(dir:string) {
   for(const item of fs.readdirSync(dir,{withFileTypes:true})) {
    if(item.name==='.godot')continue;
    const full=path.join(dir,item.name),relative=path.relative(sandbox.project,full);
    if(item.isDirectory())scan(full);
    else if(/\.(uid|import)$/.test(relative)&&!allowed.has(relative)) {
     if(write&&scripts.includes(relative.slice(0,-4))&&relative.endsWith('.gd.uid')) {
      const target=path.join(ROOT,relative);
      if(!fs.existsSync(target))copyFile(full,target);
     } else unexpected.push(relative);
    }
   }
  }
  scan(sandbox.project);
  if(unexpected.length)throw Error('Unexpected sidecars: '+unexpected.join(', '));
  // Godot 4.7 UID resolution and older path loading are covered by native tests;
  // this audit also proves none of those identities/settings changed on import.
  writeJSON(path.join(output,'results.json'),{status:'PASS',version:sandbox.version,original_binary_sha256:sandbox.inputHash,sourceHead:gitHead(),sourceDirty:gitDirty(),command:process.argv,scripts:scripts.length,uid_count:seen.size,import_normalizations:importNormalizations,editor_health:stages.some(s=>s.status==='FAIL')?'KNOWN_EXISTING_FAIL':'PASS',sidecar_hashes:Object.fromEntries(original),stages,unexpected,write_missing_uids:write});
  console.log('GODOT_METADATA_PASS '+sandbox.version+' scripts='+scripts.length);
 } finally {sandbox.dispose();}
}
