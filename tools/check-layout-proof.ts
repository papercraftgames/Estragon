/** B2 native-only two-engine proof; contributor orchestration uses TypeScript/Yarn. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, runCommand, sourceHashes, listGDScripts, gitHead, gitDirty, writeJSON } from './compat-kit.ts';
const argv=process.argv.slice(2), coreOnly=argv.includes('--core-only');
const options=parseCLI(argv.filter(arg=>arg!=='--core-only'),{graphics:true});
fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
 const sandbox=newSandbox(selection), output=path.join(options.output,selection.label);
 fs.mkdirSync(output,{recursive:true});
 try {
  for(const dir of ['addons/estragon/compiler','addons/estragon/layout_proof','examples/node_proof','examples/layout_proof','tests/layout_proof']) copyTree(path.join(ROOT,dir),path.join(sandbox.project,dir));
  // The explicit native build must produce output from authored source, even
  // when the example includes a checked generated script for easy inspection.
  fs.rmSync(path.join(sandbox.project,'examples/layout_proof/generated'),{recursive:true,force:true});
  fs.writeFileSync(path.join(sandbox.project,'project.godot'),'config_version=5\n[application]\nconfig/name="B2 isolated proof"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=360\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n');
  const sources=[...listGDScripts(path.join(ROOT,'addons/estragon/compiler')),...listGDScripts(path.join(ROOT,'addons/estragon/layout_proof')),...listGDScripts(path.join(ROOT,'examples/node_proof')).filter(p=>!p.includes('/generated/')),...listGDScripts(path.join(ROOT,'tests/layout_proof')), ...listGDScripts(path.join(ROOT,'examples/layout_proof')).filter(p=>!p.includes('/generated/')),path.join(ROOT,'examples/layout_proof/.proof/Layout.gogo'),path.join(ROOT,'tools/check-layout-proof.ts'),path.join(ROOT,'tools/compat-kit.ts')].map(p=>path.relative(ROOT,p));
  const stages:Record<string,unknown>={};
  writeJSON(path.join(output,'provenance.json'),{version:sandbox.version,original_binary_sha256:sandbox.inputHash,sourceHead:gitHead(),sourceDirty:gitDirty(),sourceHashes:sourceHashes(sources),command:process.argv});
  async function run(name:string,script:string,marker:string,graphics=false) {
   const stage=await runCommand([sandbox.binary,...(graphics?[]:['--headless']),'--audio-driver','Dummy','--path',sandbox.project,'--script',script],sandbox.workspace,sandbox.env,path.join(output,name+'.log'),marker,{abortOnError:true});
   const log=fs.readFileSync(path.join(output,name+'.log'),'utf8');
   if(/ObjectDB instances leaked|Resources still in use/.test(log)) {stage.status='FAIL';stage.reason='Native resource leak';}
   stages[name]=stage;
   process.stdout.write(log);
   writeJSON(path.join(output,'results.json'),stages);
   if(stage.status!=='PASS')throw Error('B2 '+name+' failed');
  }
  await run('core','res://tests/layout_proof/core.gd','GGX_B2_CORE_OK');
  if(!coreOnly) {
   await run('build','res://examples/layout_proof/build.gd','GGX_B2_BUILD_OK');
   await run('runtime','res://tests/layout_proof/runtime.gd','GGX_B2_RUNTIME_OK',true);
   if(options.graphics) {
    await run('visual','res://tests/layout_proof/visual.gd','GGX_B2_VISUAL_OK',true);
    for(const name of fs.readdirSync(sandbox.project).filter(p=>p.endsWith('.png')))fs.copyFileSync(path.join(sandbox.project,name),path.join(output,name));
   }
   copyTree(path.join(sandbox.project,'examples/layout_proof/generated'),path.join(output,'generated'));
  }
  console.log('GGX_B2_PASS '+sandbox.version);
 } finally {sandbox.dispose();}
}
