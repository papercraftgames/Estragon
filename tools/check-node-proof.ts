/** ADR-0015-B1 isolated Godot-only acceptance. Run with Yarn/Node, no packages. */
import { cpSync, mkdirSync, readFileSync, writeFileSync, chmodSync, existsSync, utimesSync } from 'node:fs';
import { resolve, join, relative } from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { indexProject, listGDScripts, gitDirty, gitHead, sourceHashes } from './compat-kit.ts';
const args = process.argv.slice(2);
function option(name: string): string { const i = args.indexOf(name); if (i < 0 || !args[i + 1]) throw Error(`Required ${name}`); return args[i + 1]!; }
const engine = resolve(option('--engine')), output = resolve(option('--output'));
const phase = args.includes('--phase') ? option('--phase') : 'all';
if (!['all','build','runtime','negative','editor','visual'].includes(phase)) throw Error('Unknown phase');
if (phase === 'all' && existsSync(output)) throw Error('Use a fresh output directory for acceptance');
const root = resolve(import.meta.dirname, '..'), project = join(output, 'project');
mkdirSync(output, {recursive:true});
const originalSha = createHash('sha256').update(readFileSync(engine)).digest('hex');
if (process.platform === 'darwin') {
 const pins = JSON.parse(readFileSync(join(root, 'tests/compatibility/engines.json'), 'utf8'));
 if (!pins.some((pin: {version: string; binary_sha256: string}) => ['4.0.4.stable.official.fc0b241c9', '4.7.stable.official.5b4e0cb0f'].includes(pin.version) && pin.binary_sha256 === originalSha)) throw Error('Binary is not one of the two official macOS pins');
}
const binary = join(output, 'godot');
if (!existsSync(binary)) {
 cpSync(engine, binary); chmodSync(binary, 0o755);
 if (process.platform === 'darwin') {
  const signed = spawnSync('/usr/bin/codesign', ['--force','--sign','-',binary], {encoding:'utf8'});
  if (signed.status !== 0) throw Error(signed.stderr);
 }
 writeFileSync(join(output, '_sc_'), '');
}
const version = spawnSync(binary,['--headless','--version'],{encoding:'utf8', timeout:10000, killSignal:'SIGKILL'}).stdout?.trim();
const approved = ['4.0.4.stable.official.fc0b241c9','4.7.stable.official.5b4e0cb0f'];
if (!version || !approved.includes(version)) throw Error(`Unapproved engine: ${version}`);
// Exact macOS binary provenance was checked before launch; other platforms use
// the CI-verified official archive and the same strict runtime version pin.
const sources = [
 ...listGDScripts(join(root, 'addons/estragon/compiler')),
 ...listGDScripts(join(root, 'addons/estragon/runtime')),
 ...listGDScripts(join(root, 'tests/node_proof')),
 ...listGDScripts(join(root, 'examples/node_proof')).filter(path => !path.includes('/generated/')),
 join(root, 'examples/node_proof/.proof/Composition.gogo'),
 join(root, 'tools/check-node-proof.ts'), join(root, 'tools/compat-kit.ts'),
].map(path => relative(root, path)).sort();
writeFileSync(join(output,'provenance.json'),JSON.stringify({version,originalSha,sourceHead:gitHead(),sourceDirty:gitDirty(),sourceHashes:sourceHashes(sources),command:process.argv,platform:process.platform},null,2)+'\n');
mkdirSync(join(output,'no-tools'),{recursive:true});
function run(name: string, flags: string[], marker: string, negative = false) {
 const result = spawnSync(binary,[...flags,'--audio-driver','Dummy','--path',project],{encoding:'utf8',env:{...process.env,PATH:join(output,'no-tools')},timeout:60000,killSignal:'SIGKILL',maxBuffer:16*1024*1024});
 const log = ((result.stdout||'')+(result.stderr||'')).replace(/\u001b\[[0-9;]*m/g, ''); writeFileSync(join(output,name+'.log'),log);
 process.stdout.write(log);
 if (result.status !== 0 || result.error || (marker !== "" && !log.split(/\r?\n/).includes(marker))) throw Error(`${name} failed: ${result.error||result.status}`);
 if (!negative && /SCRIPT ERROR:|^ERROR:|Parse Error:|Assertion failed:/m.test(log)) throw Error(`Unexpected native diagnostic in ${name}`);
 if (negative) {
  const errors = log.split(/\r?\n/).filter(line => /SCRIPT ERROR:|^ERROR:/.test(line));
  const allowed = [/^SCRIPT ERROR: Parse Error: Cannot pass a value of type "int" as "(?:Vector2|Callable)"\.$/, /^SCRIPT ERROR: Parse Error: Invalid argument for "_gogo_build_0\(\)" function: argument 1 should be "(?:Vector2|Callable)" but is "int"\.$/, /^SCRIPT ERROR: Parse Error: Identifier "missing_handler" not declared in the current scope\.$/, /^ERROR: invalid-callable\.gogo:3:33: B1 signal timeout requires a valid Callable\/connection$/];
  if (errors.some(line => !allowed.some(pattern => pattern.test(line)))) throw Error('Unexpected negative diagnostic: '+errors.join('\n'));
  if ((log.match(/^B1_EXPECTED_SEMANTIC_REJECTION /gm)||[]).length !== 3 || !log.includes('B1_EXPECTED_CALLBACK_REJECTION')) throw Error('Missing negative probe');
 }
 if (/instances leaked|Resources still in use|B1 ASSERTION FAILED|B1 EDITOR ASSERTION FAILED/i.test(log)) throw Error('Leak or assertion failure');
}
// Refresh only fixture/compiler files for focused development phases; the output
// directory retains runtime-generated artifacts needed by editor persistence.
mkdirSync(join(project,'addons/estragon'),{recursive:true});
cpSync(join(root,'addons/estragon/compiler'),join(project,'addons/estragon/compiler'),{recursive:true});
cpSync(join(root,'addons/estragon/runtime'),join(project,'addons/estragon/runtime'),{recursive:true});
cpSync(join(root,'examples/node_proof'),join(project,'examples/node_proof'),{recursive:true});
cpSync(join(root,'tests/node_proof'),join(project,'tests/node_proof'),{recursive:true});
for(const example of ['compiled','mixed','counter']) cpSync(join(root,'examples',example),join(project,'examples',example),{recursive:true});
const settings = `config_version=5\n[application]\nconfig/name="B1 isolated proof"\nrun/main_scene="res://examples/node_proof/Main.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[display]\nwindow/size/viewport_width=360\nwindow/size/viewport_height=220\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n`;
writeFileSync(join(project,'project.godot'),settings);
if (phase==='all'||phase==='build') {
 run('build',['--headless','--script','res://examples/node_proof/build.gd'],'GGX_B1_BUILD_OK');
 const indexed = await indexProject({workspace:output, binary, env:{...process.env, PATH:join(output,'no-tools')}, version, known:{}, inputHash:originalSha, project, dispose:()=>{}}, project, join(output,'import.log'), ['--audio-driver','Dummy']);
 process.stdout.write(readFileSync(join(output,'import.log'),'utf8'));
 if (indexed.status !== 'PASS') throw Error('Native class indexing failed: '+JSON.stringify(indexed));
}
if (phase==='all'||phase==='runtime') run('runtime',['--headless','--script','res://tests/node_proof/runtime.gd'],'GGX_B1_RUNTIME_OK');
if (phase==='all'||phase==='negative') {
 for (const name of ['Composition.gd', 'Composition.gd.map.json']) utimesSync(join(project,'examples/node_proof/generated',name), 1234567890, 1234567890);
 run('negative',['--script','res://tests/node_proof/negative.gd'],'GGX_B1_NEGATIVE_OK',true);
}
if (phase==='all'||phase==='editor') {
 writeFileSync(join(project,'project.godot'),settings+'\n[editor_plugins]\nenabled=PackedStringArray("res://tests/node_proof/editor/plugin.cfg")\n');
 for(const pass of [1,2]) run('editor-'+pass,['--editor'],'GGX_B1_EDITOR_OK');
 writeFileSync(join(project,'project.godot'),settings);
}
if (phase==='visual') run('visual',['--script','res://tests/node_proof/visual.gd'],'GGX_B1_VISUAL_OK');
console.log(`GGX_B1_${phase.toUpperCase()}_PASS ${version}`);
