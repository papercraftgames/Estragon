/** Pinned binary cache authentication is mandatory on both cache hits and misses. */
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';
import { sha256 } from './compat-kit.ts';
export function verifyEngine(binary:string,expected:{binary_sha256:string;version:string},readVersion=(file:string)=>execFileSync(file,['--headless','--version'],{encoding:'utf8',timeout:60000}).trim()) {
    if(!fs.lstatSync(binary).isFile() || sha256(binary)!==expected.binary_sha256)throw Error('Godot executable SHA256 mismatch');
    fs.chmodSync(binary,0o755);
    if(readVersion(binary)!==expected.version)throw Error('Official engine version mismatch');
}
