/** Fetch and authenticate exactly the approved Godot 4.0.4 macOS runner. */
import * as fs from "node:fs";
import * as path from "node:path";
import { execFileSync } from "node:child_process";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { ROOT, fail, readJSON, sha256 } from "./compat-kit.ts";

async function main(): Promise<void> {
  const destination = process.env.RUNNER_TEMP;
  const githubEnv = process.env.GITHUB_ENV;
  if (!destination || !githubEnv) fail("This is a GitHub Actions setup tool");
  const manifest = readJSON<Array<{
    version: string; official_archive_url?: string;
    archive_sha256?: string; binary_sha256: string;
  }>>(path.join(ROOT, "tests/compatibility/engines.json"));
  const engine = manifest.find(row => row.version.startsWith("4.0.4.stable."));
  if (!engine?.official_archive_url || !engine.archive_sha256) fail("Missing pinned 4.0.4 download data");
  const archive = path.join(destination, "official-4.0.4.zip");
  const response = await fetch(engine.official_archive_url);
  if (!response.ok || !response.body) fail("Godot download failed: " + response.status);
  await pipeline(Readable.fromWeb(response.body as any),
    fs.createWriteStream(archive));
  if (sha256(archive) !== engine.archive_sha256) fail("Godot archive SHA256 mismatch");
  const extracted = path.join(destination, "godot-verified");
  fs.mkdirSync(extracted, { recursive: true });
  execFileSync("/usr/bin/unzip", ["-q", archive, "Godot.app/Contents/MacOS/Godot", "-d", extracted]);
  const binary = path.join(destination, "official-godot");
  fs.copyFileSync(path.join(extracted, "Godot.app/Contents/MacOS/Godot"), binary);
  if (sha256(binary) !== engine.binary_sha256) fail("Godot executable SHA256 mismatch");
  fs.chmodSync(binary, 0o755);
  fs.appendFileSync(githubEnv, "GODOT_BIN=" + binary + "\n");
  console.log("Verified Godot 4.0.4 official binary and archive");
}
main().catch(error => { console.error(error); process.exitCode = 1; });
