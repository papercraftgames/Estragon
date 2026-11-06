/** P01: npm-format addon installed with Yarn into a real isolated Godot consumer. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, indexProject, runCommand, sha256, writeJSON, gitHead, gitDirty } from './compat-kit.ts';
const options=parseCLI(process.argv.slice(2));fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
    const box=newSandbox(selection),out=path.join(options.output,selection.label), stages:Record<string,any>={};fs.mkdirSync(out,{recursive:true});
    try {
        writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
        async function command(name:string,args:string[],cwd:string,env:NodeJS.ProcessEnv,marker?:string,negative=false) {
            const logFile=path.join(out,name+'.log');
            const stage=await runCommand(args,cwd,env,logFile,marker,{abortOnError:!negative,expectedErrors:negative,timeout:negative?240000:120000});
            const log=fs.readFileSync(logFile,'utf8');process.stdout.write(log);
            if(negative) {
                const lines=log.split(/\r?\n/);
                stage.unexpected_errors=lines.filter((line,i)=>{
                    if(!/SCRIPT ERROR:|^ERROR:|Parse Error:|Assertion failed:/.test(line))return false;
                    if(line==='ERROR: An EditorPlugin build callback failed.' || line==="ERROR: Cannot save text file 'res://examples/counter/Counter.gogo'.")return false;
                    if((/^SCRIPT ERROR: Parse Error:/.test(line) && /res:\/\/examples\/counter\/generated\/Counter\.gd:\d+\)/.test(lines[i+1]||'') || /^examples\/counter\/Counter\.gogo:\d+:\d+: Parse Error:/.test(line)) && /Identifier "missing_handler" not declared|Cannot assign|Cannot find member|Invalid argument|Cannot pass|Cannot convert/.test(line))return false;
                    return true;
                });
                if((stage.unexpected_errors as string[]).length || /PACKAGE_EDITOR_CHECK .*: false/.test(log)||!log.includes('PACKAGE_EDITOR_CHECK'))stage.status='FAIL';
            }
            if(/instances leaked|Resources still in use/.test(log))stage.status='FAIL';
            stages[name]=stage;writeJSON(path.join(out,'results.json'),stages);if(stage.status!=='PASS')throw Error('Package consumer '+name+' failed');
        }
        const packed=path.join(out,'packed');
        await command('pack',[process.execPath,'--experimental-strip-types',path.join(ROOT,'tools/pack-addon.ts'),packed,'--require-clean'],box.workspace,process.env,'PACKAGE_PACK_OK');
        const manifest=JSON.parse(fs.readFileSync(path.join(packed,'package-manifest.json'),'utf8'));
        fs.mkdirSync(box.project,{recursive:true});
        writeJSON(path.join(box.project,'package.json'),{name:'estragon-native-consumer',private:true,packageManager:'yarn@1.22.22'});
        await command('install',['corepack','yarn@1.22.22','add','--exact','--ignore-scripts','--non-interactive','--offline','--cache-folder',path.join(box.workspace,'yarn-cache'),'file:'+path.join(packed,manifest.tarball)],box.project,process.env);
        const installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
        for(const [file,hash]of Object.entries(manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Yarn-installed payload hash mismatch: '+file);
        // These explicit copy/ignore steps are exactly the documented install contract.
        fs.writeFileSync(path.join(box.project,'node_modules/.gdignore'),'');
        fs.mkdirSync(path.join(box.project,'addons'),{recursive:true});
        fs.cpSync(path.join(installed,'addons/estragon'),path.join(box.project,'addons/estragon'),{recursive:true});
        const settings='config_version=5\n[application]\nconfig/name="P01 standalone package consumer"\nrun/main_scene="res://examples/counter/Counter.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
        fs.writeFileSync(path.join(box.project,'project.godot'),settings);
        writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['examples/counter']});
        // Only the canonical authored source/scene, no repository generated code or assets.
        fs.mkdirSync(path.join(box.project,'examples/counter'),{recursive:true});
        for(const name of ['Counter.gogo','Counter.tscn'])fs.copyFileSync(path.join(ROOT,'examples/counter',name),path.join(box.project,'examples/counter',name));
        copyTree(path.join(ROOT,'tests/package-consumer'),path.join(box.project,'tests/package-consumer'));
        async function godot(name:string,args:string[],marker:string,graphics=false,negative=false) {await command(name,[box.binary,...(graphics?[]:['--headless']),'--audio-driver','Dummy','--path',box.project,...args],box.workspace,box.env,marker,negative);}
        await godot('build',['--script','res://tests/package-consumer/build.gd'],'PACKAGE_BUILD_OK');
        copyTree(path.join(box.project,'examples/counter/generated'),path.join(out,'generated'));
        stages.import=await indexProject(box,box.project,path.join(out,'import.log'),['--audio-driver','Dummy']);
        if(stages.import.status!=='PASS')throw Error('Package consumer import failed');
        await godot('runtime',['--script','res://tests/package-consumer/runtime.gd'],'PACKAGE_RUNTIME_OK',true);
        fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("res://addons/estragon/editor/plugin.cfg", "res://tests/package-consumer/editor/plugin.cfg")\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
        box.env.ESTRAGON_C3_PROOF='1';await godot('editor',['--editor'],'PACKAGE_EDITOR_OK',false,true);delete box.env.ESTRAGON_C3_PROOF;
        fs.writeFileSync(path.join(box.project,'project.godot'),settings);
        await godot('visual',['--script','res://tests/package-consumer/visual.gd'],'PACKAGE_VISUAL_OK',true);
        for(const name of fs.readdirSync(box.project).filter(p=>p.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,name));
        for(const [file,hash]of Object.entries(manifest.files))if(file.startsWith('addons/') && sha256(path.join(box.project,file))!==hash)throw Error('Godot changed installed addon/UID payload: '+file);
        writeJSON(path.join(out,'consumer-audit.json'),{sourceHead:gitHead(),installed_tarball_sha256:manifest.tarball_sha256,source_content_sha256:manifest.source_content_sha256,addon_payload_unchanged:true,node_modules_ignored:true,external_compiler:false});
    } finally {writeJSON(path.join(out,'results.json'),stages);box.dispose();}
}
