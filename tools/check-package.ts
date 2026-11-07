/** P02: npm-format addon installed with Yarn into a real isolated Godot consumer. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT, parseCLI, newSandbox, copyTree, indexProject, runCommand, sha256, writeJSON, gitHead, gitDirty } from './compat-kit.ts';
const published=process.env.ESTRAGON_PUBLISHED_PACKAGE_DIRECTORY;
const directOnly=process.argv.includes('--direct-only');
const options=parseCLI(process.argv.slice(2).filter(arg=>arg!=='--direct-only'));fs.mkdirSync(options.output,{recursive:true});
for(const selection of options.engines) {
    const box=newSandbox(selection),out=path.join(options.output,selection.label), stages:Record<string,any>={};fs.mkdirSync(out,{recursive:true});
    let phase='package';
    try {
        writeJSON(path.join(out,'provenance.json'),{sourceHead:gitHead(),sourceDirty:gitDirty(),version:box.version,original_binary_sha256:box.inputHash});
        async function command(name:string,args:string[],cwd:string,env:NodeJS.ProcessEnv,marker?:string,negative=false) {
            const logFile=path.join(out,phase+'-'+name+'.log');
            const stage=await runCommand(args,cwd,env,logFile,marker,{abortOnError:!negative,expectedErrors:negative,timeout:negative?240000:120000});
            const log=fs.readFileSync(logFile,'utf8');process.stdout.write(log);
            if(!stage.log || !fs.existsSync(path.join(out,stage.log)))throw Error('Stage log is not directly addressable by the release verifier: '+name);
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
            stage.layout=phase;
            const previous=stages[name];
            stages[name]={...stage, runs:[...(previous?.runs || []), stage]};writeJSON(path.join(out,'results.json'),stages);if(stage.status!=='PASS')throw Error('Package consumer '+name+' failed');
        }
        const packed=path.join(out,'packed');
        await command('pack',published?[process.execPath,'--experimental-strip-types',path.join(ROOT,'tools/verify-published-package.ts'),published,packed]:[process.execPath,'--experimental-strip-types',path.join(ROOT,'tools/pack-addon.ts'),packed,'--require-clean'],box.workspace,process.env,'PACKAGE_PACK_OK');
        const manifest=JSON.parse(fs.readFileSync(path.join(packed,'package-manifest.json'),'utf8'));
        const originalProject = box.project;
        const layouts = [
            ['direct', 'node_modules/@papercraftgames/estragon/addons/estragon'],
            ['relocated', 'modules/UI toolkit'],
            ['standard', 'addons/estragon'],
        ] as const;
        for (const [layout, addonRoot] of (directOnly ? layouts.slice(0,1) : layouts)) {
            phase=layout;
            box.project = originalProject + '-' + layout;
            fs.mkdirSync(box.project,{recursive:true});
            writeJSON(path.join(box.project,'package.json'),{name:'estragon-native-consumer',private:true,packageManager:'yarn@1.22.22'});
            await command('install',['corepack','yarn@1.22.22','add','--exact','--ignore-scripts','--non-interactive',...(published?[]:['--offline']),'--cache-folder',path.join(box.workspace,'yarn-cache'),published?'@papercraftgames/estragon@'+manifest.version:'file:'+path.join(packed,manifest.tarball)],box.project,process.env);
            const installed=path.join(box.project,'node_modules/@papercraftgames/estragon');
            for(const [file,hash]of Object.entries(manifest.files))if(sha256(path.join(installed,file))!==hash)throw Error('Yarn-installed payload hash mismatch: '+file);
            // The direct case uses Yarn's original tree. Other cases move that one
            // tree before import, proving relocation without duplicate classes/UIDs.
            const addon=path.join(box.project,addonRoot!);
            if(layout!=='direct') {
                fs.mkdirSync(path.dirname(addon),{recursive:true});
                fs.renameSync(path.join(installed,'addons/estragon'),addon);
            }
            for(let current=addon;current!==box.project;current=path.dirname(current)) {
                if(fs.lstatSync(current).isSymbolicLink() || fs.existsSync(path.join(current,'.gdignore')))throw Error('Addon must be directly visible without symlinks: '+current);
            }
            const resourceRoot='res://'+addonRoot;
            const configureFixture=(file:string)=>fs.writeFileSync(file,fs.readFileSync(file,'utf8').replaceAll('res://addons/estragon',resourceRoot));
            const settings='config_version=5\n[application]\nconfig/name="P02 direct package consumer"\nrun/main_scene="res://examples/counter/Counter.tscn"\nconfig/features=PackedStringArray("4.0", "GL Compatibility")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n';
            fs.writeFileSync(path.join(box.project,'project.godot'),settings);
            writeJSON(path.join(box.project,'gogo.config.json'),{version:1,source_roots:['examples/counter']});
            // Only the canonical authored source/scene, no repository generated code or assets.
            fs.mkdirSync(path.join(box.project,'examples/counter'),{recursive:true});
            for(const name of ['Counter.gogo','Counter.tscn'])fs.copyFileSync(path.join(ROOT,'examples/counter',name),path.join(box.project,'examples/counter',name));
            copyTree(path.join(ROOT,'tests/package-consumer'),path.join(box.project,'tests/package-consumer'));
            for(const relative of ['build.gd','runtime.gd','editor/driver.gd'])configureFixture(path.join(box.project,'tests/package-consumer',relative));
            const counter=path.join(box.project,'examples/counter/Counter.gogo');
            fs.writeFileSync(counter,fs.readFileSync(counter,'utf8').replaceAll('../../../addons/estragon',path.posix.relative('examples/counter/generated',addonRoot!)));
            fs.copyFileSync(path.join(ROOT,'tests/package-consumer/Binding.gogo'),path.join(box.project,'examples/counter/Binding.gogo'));
            configureFixture(path.join(box.project,'examples/counter/Binding.gogo'));
            if(layout!=='standard' && fs.existsSync(path.join(box.project,'addons/estragon')))throw Error('Forbidden canonical addon fallback');
            if(fs.existsSync(path.join(box.project,'node_modules/.gdignore')))throw Error('Direct package must remain visible to Godot');
            async function godot(name:string,args:string[],marker:string,graphics=false,negative=false) {await command(name,[box.binary,...(graphics?[]:['--headless']),'--audio-driver','Dummy','--path',box.project,...args],box.workspace,box.env,marker,negative);}
            await godot('build',['--script','res://tests/package-consumer/build.gd'],'PACKAGE_BUILD_OK');
            copyTree(path.join(box.project,'examples/counter/generated'),path.join(out,layout!,'generated'));
            for(const name of fs.readdirSync(path.join(box.project,'examples/counter/generated')).filter(p=>p.endsWith('.gd'))) {
                const code=fs.readFileSync(path.join(box.project,'examples/counter/generated',name),'utf8');
                // Authored absolute imports are legitimate; injected preloads are relative.
                if(/preload\("res:\/\/[^"]*runtime\/composition\/(?:state\.tres|binding\.gd)/.test(code))throw Error('Absolute injected dependency');
            }
            const imported=await indexProject(box,box.project,path.join(out,layout+'-import.log'),['--audio-driver','Dummy']);
            imported.layout=layout;
            stages.import={...imported,runs:[...(stages.import?.runs || []),imported]};
            if(imported.status!=='PASS')throw Error('Package consumer import failed');
            await godot('runtime',['--script','res://tests/package-consumer/runtime.gd'],'PACKAGE_RUNTIME_OK',true);
            // Prove cold activation builds source before the requested scene opens;
            // neither CLI-generated executables nor an earlier editor cache may help.
            const generated=path.join(box.project,'examples/counter/generated');
            const uids=Object.fromEntries(fs.readdirSync(generated).filter(name=>name.endsWith('.uid')).map(name=>[name,sha256(path.join(generated,name))]));
            fs.rmSync(path.join(box.project,'.godot'),{recursive:true,force:true});
            for(const name of fs.readdirSync(generated).filter(name=>!name.endsWith('.uid')))fs.rmSync(path.join(generated,name));
            fs.appendFileSync(path.join(box.project,'project.godot'),'\n[editor_plugins]\nenabled=PackedStringArray("'+resourceRoot+'/editor/plugin.cfg", "res://tests/package-consumer/editor/plugin.cfg")\n[editor]\nrun/main_run_args="--headless --audio-driver Dummy"\n');
            box.env.ESTRAGON_C3_PROOF='1';await godot('editor',['--editor','res://examples/counter/Counter.tscn'],'PACKAGE_EDITOR_OK',false,true);delete box.env.ESTRAGON_C3_PROOF;
            for(const [name,hash] of Object.entries(uids))if(sha256(path.join(generated,name))!==hash)throw Error('Cold editor changed generated UID: '+name);
            fs.writeFileSync(path.join(box.project,'project.godot'),settings);
            await godot('visual',['--script','res://tests/package-consumer/visual.gd'],'PACKAGE_VISUAL_OK',true);
            for(const name of fs.readdirSync(box.project).filter(p=>p.endsWith('.png')))fs.copyFileSync(path.join(box.project,name),path.join(out,layout+'-'+name));
            for(const [file,hash]of Object.entries(manifest.files))if(file.startsWith('addons/') && sha256(path.join(addon,path.relative('addons/estragon',file)))!==hash)throw Error('Godot changed installed addon/UID payload: '+file);
            writeJSON(path.join(out,layout+'-consumer-audit.json'),{sourceHead:gitHead(),installed_tarball_sha256:manifest.tarball_sha256,source_content_sha256:manifest.source_content_sha256,addon_payload_unchanged:true,layout,addon_root:resourceRoot,node_modules_ignored:false,addon_copied:false,addon_symlinked:false,external_compiler:false});
        }
    } finally {writeJSON(path.join(out,'results.json'),stages);box.dispose();}
}
