/** Authenticate only the two owner-approved official Linux engines. */
import * as fs from "node:fs";
import * as path from "node:path";
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { ROOT, fail, readJSON, sha256 } from "./compat-kit.ts";
async function main(): Promise<void> {
  if(process.platform!=="linux")fail("Routine verification is Linux-only (owner #81)");
  const destination=process.env.RUNNER_TEMP, githubEnv=process.env.GITHUB_ENV;
  if(!destination||!githubEnv)fail("This is a GitHub Actions setup tool");
  const label=process.env.GODOT_VERSION||"4.0.4";
  if(!["4.0.4","4.7"].includes(label))fail("Only approved 4.0.4 / pinned 4.7.0");
  const manifest=readJSON<Array<{version:string;official_archive_url:string;archive_file:string;archive_sha256:string;binary_sha256:string;official_checksums_url?:string;archive_sha512?:string}>>(path.join(ROOT,"tests/compatibility/linux-engines.json"));
  const engine=manifest.find(row=>row.version.startsWith(label+".stable."));
  if(!engine)fail("Missing pinned Linux engine data");
  const response=await fetch(engine.official_archive_url);
  if(!response.ok||!response.body)fail("Godot download failed: "+response.status);
  const archive=path.join(destination,"official-"+label+".zip");
  await pipeline(Readable.fromWeb(response.body as any),fs.createWriteStream(archive));
  if(sha256(archive)!==engine.archive_sha256)fail("Godot archive SHA256 mismatch");
  if(engine.official_checksums_url&&engine.archive_sha512){
    const checksumResponse=await fetch(engine.official_checksums_url);
    if(!checksumResponse.ok)fail("Official SHA512 manifest unavailable");
    const checksums=await checksumResponse.text();
    const line=checksums.split(/\r?\n/).find(line=>line.trim().endsWith(engine.archive_file+".zip"));
    if(!line||line.trim().split(/\s+/)[0]!==engine.archive_sha512)fail("Official SHA512 manifest identity mismatch");
    if(createHash("sha512").update(fs.readFileSync(archive)).digest("hex")!==engine.archive_sha512)fail("Official archive SHA512 mismatch");
    fs.writeFileSync(path.join(destination,"official-"+label+"-SHA512-SUMS.txt"),checksums);
  }
  const extracted=path.join(destination,"godot-verified-"+label);
  fs.mkdirSync(extracted,{recursive:true});
  execFileSync("unzip",["-q",archive,engine.archive_file,"-d",extracted]);
  const binary=path.join(extracted,engine.archive_file);
  if(sha256(binary)!==engine.binary_sha256)fail("Godot executable SHA256 mismatch");
  fs.chmodSync(binary,0o755);
  if(execFileSync(binary,["--headless","--version"],{encoding:"utf8"}).trim()!==engine.version)fail("Official engine version mismatch");
  fs.appendFileSync(githubEnv,"GODOT_BIN="+binary+"\n");
  console.log("VERIFIED_OFFICIAL_LINUX "+engine.version+" archive="+engine.archive_sha256+" binary="+engine.binary_sha256);
}
main().catch(error=>{console.error(error);process.exitCode=1;});
