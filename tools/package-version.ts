/** Git is a development checkout; release versions belong to validated tags. */
import * as fs from 'node:fs';
import * as path from 'node:path';
import { ROOT } from './compat-kit.ts';
export const DEVELOPMENT_VERSION='0.0.0-dev';
export const OVERLAY_RECIPE='estragon-tag-overlay-v1';
export function tagVersion(tag:unknown):string {
    if(typeof tag!=='string' || tag.length>100 || !/^v0\.(0|[1-9]\d*)\.(0|[1-9]\d*)-beta\.(0|[1-9]\d*)$/.test(tag))throw Error('Unsupported prerelease tag');
    if(tag.slice(1).split(/[.-]/).filter(v=>/^\d+$/.test(v)).some(v=>!Number.isSafeInteger(Number(v))))throw Error('Unsafe version component');
    return tag.slice(1);
}
export function pluginVersion(config:string):string {
    const entries=[...config.matchAll(/^version\s*=\s*"([^"\r\n]+)"\s*$/gm)];
    if(entries.length!==1)throw Error('Expected exactly one Godot plugin version field');
    return entries[0]![1]!;
}
export function addonVersion(root=ROOT):string {
    const version=pluginVersion(fs.readFileSync(path.join(root,'addons/estragon/editor/plugin.cfg'),'utf8'));
    if(version!==DEVELOPMENT_VERSION)throw Error('Git plugin metadata must identify a development checkout');
    return version;
}
function stagingVersion(version:string) {if(version!==DEVELOPMENT_VERSION)tagVersion('v'+version);}
export function stagedPluginCfg(config:string,version:string):string {
    stagingVersion(version);
    if(pluginVersion(config)!==DEVELOPMENT_VERSION)throw Error('Overlay requires immutable development source');
    return config.replace(/^(version\s*=\s*")[^"\r\n]+("\s*)$/m,(_,left,right)=>left+version+right);
}
export function stagedPackageJson(spec:Record<string,unknown>,version:string):string {
    if(Object.hasOwn(spec,'version'))throw Error('The checked-in npm package manifest must not define a second version');
    stagingVersion(version);
    return JSON.stringify({...spec,version},null,2)+'\n';
}
