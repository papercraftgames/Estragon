/** The Godot plugin metadata is the only committed Estragon package-version source. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT } from './compat-kit.ts';

export function addonVersion(root=ROOT):string {
    const file=path.join(root,'addons/estragon/editor/plugin.cfg');
    const config=fs.readFileSync(file,'utf8');
    const entries=[...config.matchAll(/^version\s*=\s*"([^"\r\n]+)"\s*$/gm)];
    if(entries.length!==1)throw Error('Expected exactly one Godot plugin version field');
    const version=entries[0]![1]!;
    if(!/^0\.\d+\.\d+-beta\.\d+$/.test(version))throw Error('Unsupported Godot plugin release version: '+version);
    return version;
}

export function stagedPackageJson(spec:Record<string,unknown>,version:string):string {
    if(Object.hasOwn(spec,'version'))throw Error('The checked-in npm package manifest must not define a second version');
    if(!/^0\.\d+\.\d+-beta\.\d+$/.test(version))throw Error('Invalid staging version');
    return JSON.stringify({...spec,version},null,2)+'\n';
}
