/**
 * Native-Godot test orchestration. TypeScript only; no Python/runtime addon dependency.
 * Deliberately limited to the two owner-approved Godot versions.
 */
import { createHash } from "node:crypto";
import { spawn, execFileSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const ERROR = /SCRIPT ERROR:|(?:^|\n)ERROR:|Parse Error:|Assertion failed:/;
const ANSI = /\x1b\[[0-9;]*m/g;
export type Outcome = "PASS" | "FAIL" | "BLOCKED" | "UNTESTED";
export type Stage = { status: Outcome; reason?: string; command?: string[]; exit_code?: number | null;
  timeout?: boolean; aborted_on_error?: boolean; seconds?: number; log?: string;
  diagnostics?: string[]; evidence?: unknown; [key: string]: unknown };
export type EngineSelection = { label: "4.0.4" | "4.7"; binary: string };
export type CliArgs = { engines: EngineSelection[]; output: string; editor: boolean; graphics: boolean; collectOnly: boolean };
export type Sandbox = { workspace: string; binary: string; env: NodeJS.ProcessEnv; version: string;
  known: Record<string, unknown>; inputHash: string; project: string; dispose: () => void };
export type EngineRecord = { label: string; version?: string; input_binary_sha256?: string;
  provenance?: unknown; stages: Record<string, Stage>; [key: string]: unknown };

export function fail(message: string): never { throw new Error(message); }
export function parseCLI(argv: string[], options: { editor?: boolean; graphics?: boolean; collectOnly?: boolean } = {}): CliArgs {
  const engines: EngineSelection[] = [];
  let output = "";
  let editor = false;
  let graphics = false;
  let collectOnly = false;
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]!;
    if (arg === "--engine") {
      const selection = argv[++i] || "";
      const equal = selection.indexOf("=");
      const label = selection.slice(0, equal);
      const binary = selection.slice(equal + 1);
      if (equal < 1 || !binary || !path.isAbsolute(binary) || !["4.0.4", "4.7"].includes(label)) {
        fail("Only approved --engine 4.0.4=/absolute/godot or 4.7=/absolute/godot is allowed");
      }
      engines.push({ label: label as EngineSelection["label"], binary });
    } else if (arg === "--output") {
      output = argv[++i] || "";
    } else if (arg === "--editor" && options.editor) {
      editor = true;
    } else if (arg === "--graphics" && options.graphics) {
      graphics = true;
    } else if (arg === "--collect-only" && options.collectOnly) {
      collectOnly = true;
    } else {
      fail("Unknown or missing argument: " + arg);
    }
  }
  if (!engines.length || engines.length > 2 || new Set(engines.map(e => e.label)).size !== engines.length) {
    fail("At most two distinct Godot engines: 4.0.4 and pinned 4.7.0");
  }
  if (!output || !path.isAbsolute(output)) fail("--output must be a new absolute directory");
  if (fs.existsSync(output)) fail("Output directory must be new: " + output);
  return { engines, output, editor, graphics, collectOnly };
}

export function sha256(file: string): string {
  return createHash("sha256").update(fs.readFileSync(file)).digest("hex");
}
export function writeJSON(file: string, data: unknown): void {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
}
export function readJSON<T = unknown>(file: string): T {
  return JSON.parse(fs.readFileSync(file, "utf8")) as T;
}
export function copyFile(from: string, to: string): void {
  fs.mkdirSync(path.dirname(to), { recursive: true });
  fs.copyFileSync(from, to);
}
export function copyTree(from: string, to: string): void {
  fs.cpSync(from, to, { recursive: true, force: true, filter: source =>
    !source.split(path.sep).includes(".godot") && !source.split(path.sep).includes("node_modules") });
}
export function sourceHashes(files: string[]): Record<string, string> {
  const hashes: Record<string, string> = {};
  for (const relative of files) hashes[relative] = sha256(path.join(ROOT, relative));
  return hashes;
}
export function gitHead(): string {
  try { return execFileSync("git", ["rev-parse", "HEAD"], { cwd: ROOT, encoding: "utf8" }).trim(); }
  catch { return "unknown"; }
}
export function gitDirty(): boolean {
  try { return execFileSync("git", ["status", "--porcelain"], { cwd: ROOT, encoding: "utf8" }).trim().length > 0; }
  catch { return false; }
}
export function unavailable(reason: string, status: Outcome = "BLOCKED"): Stage { return { status, reason }; }
export function classify(code: number | null, output: string, marker?: string, timedOut = false): Outcome {
  if (timedOut || code !== 0 || ERROR.test(output)) return "FAIL";
  if (marker && !output.split(/\r?\n/).includes(marker)) return "FAIL";
  return "PASS";
}
export function stageStatus(record: EngineRecord): Record<string, Outcome> {
  return Object.fromEntries(Object.entries(record.stages).map(([key, value]) => [key, value.status]));
}
export function recordHasFailure(records: EngineRecord[]): boolean {
  return records.some(record => Object.values(record.stages).some(stage => stage.status !== "PASS"));
}

export function newSandbox(selection: EngineSelection): Sandbox {
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "estragon-native-"));
  try {
    const binary = path.join(workspace, "godot");
    copyFile(path.resolve(selection.binary), binary);
    fs.chmodSync(binary, 0o755);
    // All editor entry points use self-contained settings, including focused
    // compiler/distribution runs; XDG alone does not isolate macOS preferences.
    fs.writeFileSync(path.join(workspace, "_sc_"), "");
    const inputHash = sha256(binary);
    // macOS executables are verified *before* ad-hoc signing copies.
    if (process.platform === "darwin") {
      execFileSync("/usr/bin/codesign", ["--force", "--sign", "-", binary], { stdio: "pipe" });
    }
    const noTools = path.join(workspace, "no-tools");
    fs.mkdirSync(noTools);
    const env: NodeJS.ProcessEnv = { ...process.env, PATH: noTools };
    for (const key of ["XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"]) {
      const folder = path.join(workspace, key.toLowerCase());
      fs.mkdirSync(folder);
      env[key] = folder;
    }
    const version = execFileSync(binary, ["--headless", "--version"],
      { cwd: workspace, env, encoding: "utf8", timeout: 60000 }).trim();
    const manifest = readJSON<Array<Record<string, unknown>>>(path.join(ROOT, process.platform === "linux" ? "tests/compatibility/linux-engines.json" : "tests/compatibility/engines.json"));
    const known = manifest.find(item => item.version === version);
    if (!known || !String(version).startsWith(selection.label === "4.7" ? "4.7.stable." : "4.0.4.stable.")) {
      fail("Official engine identity mismatch: requested " + selection.label + ", got " + version);
    }
    if (inputHash !== known.binary_sha256) {
      fail("Official engine binary SHA mismatch: " + version);
    }
    return { workspace, binary, env, version, known, inputHash,
      project: path.join(workspace, "project"), dispose: () => fs.rmSync(workspace, { recursive: true, force: true }) };
  } catch (error) {
    fs.rmSync(workspace, { recursive: true, force: true });
    throw error;
  }
}

export async function runCommand(command: string[], cwd: string, env: NodeJS.ProcessEnv,
  logFile: string, marker?: string, options: { timeout?: number; expectedErrors?: boolean;
    abortOnError?: boolean } = {}): Promise<Stage> {
  const started = Date.now();
  const timeout = options.timeout ?? 60000;
  fs.mkdirSync(path.dirname(logFile), { recursive: true });
  let output = "";
  let timedOut = false;
  let aborted = false;
  const code = await new Promise<number | null>((resolve, reject) => {
    const child = spawn(command[0]!, command.slice(1), {
      cwd, env, detached: process.platform !== "win32", stdio: ["ignore", "pipe", "pipe"],
    });
    const stop = (): void => {
      try {
        if (process.platform !== "win32" && child.pid) process.kill(-child.pid, "SIGKILL");
        else child.kill("SIGKILL");
      } catch { child.kill("SIGKILL"); }
    };
    const observe = (chunk: Buffer): void => {
      output += chunk.toString();
      if (options.abortOnError && ERROR.test(output.replace(ANSI, "")) && !aborted) {
        aborted = true;
        stop();
      }
    };
    child.stdout.on("data", observe);
    child.stderr.on("data", observe);
    const timer = setTimeout(() => { timedOut = true; stop(); }, timeout);
    child.on("error", error => { clearTimeout(timer); reject(error); });
    child.on("close", value => { clearTimeout(timer); resolve(value); });
  });
  output = output.replace(ANSI, "");
  fs.writeFileSync(logFile, output);
  const status = classify(code, options.expectedErrors ? "" : output,
    options.expectedErrors ? undefined : marker, timedOut);
  const finalStatus = options.expectedErrors && marker && !output.split(/\r?\n/).includes(marker) ? "FAIL" : status;
  return { status: finalStatus, command, exit_code: code, timeout: timedOut,
    aborted_on_error: aborted, seconds: Math.round((Date.now() - started) / 10) / 100,
    log: path.basename(logFile),
    diagnostics: output.split(/\r?\n/).filter(line => ERROR.test(line) || line.includes("at:")).slice(0, 30) };
}
export function engineRecord(selection: EngineSelection, sandbox: Sandbox): EngineRecord {
  return { label: selection.label, version: sandbox.version,
    input_binary_sha256: sandbox.inputHash, provenance: sandbox.known, stages: { engine_identity: { status: "PASS" } } };
}
export function freshProject(sandbox: Sandbox, includeExamples = false): void {
  fs.mkdirSync(sandbox.project, { recursive: true });
  copyTree(path.join(ROOT, "addons"), path.join(sandbox.project, "addons"));
  if (includeExamples) copyTree(path.join(ROOT, "examples"), path.join(sandbox.project, "examples"));
  copyFile(path.join(ROOT, "project.godot"), path.join(sandbox.project, "project.godot"));
  copyFile(path.join(ROOT, "gogo.config.json"), path.join(sandbox.project, "gogo.config.json"));
}
export async function indexProject(sandbox: Sandbox, project: string, log: string, editorArgs: string[] = []): Promise<Stage> {
  // Godot 4.0/4.1 do not support --import. Use the existing native index observer.
  const configPath = path.join(project, "project.godot");
  const original = fs.readFileSync(configPath);
  const driver = path.join(project, "tests/c01_index");
  fs.mkdirSync(driver, { recursive: true });
  try {
    const expected: Record<string, string> = {};
    const scan = (folder: string): void => {
      if (fs.existsSync(path.join(folder, ".gdignore"))) return;
      for (const item of fs.readdirSync(folder, { withFileTypes: true })) {
        if (item.name === ".godot") continue;
        const full = path.join(folder, item.name);
        if (item.isDirectory()) scan(full);
        else if (item.isFile() && full.endsWith(".gd")) {
          const hit = fs.readFileSync(full, "utf8").match(/^class_name\s+(\w+)/m);
          if (hit) expected[hit[1]!] = "res://" + path.relative(project, full).split(path.sep).join("/");
        }
      }
    };
    scan(project);
    writeJSON(path.join(driver, "expected.json"), expected);
    copyFile(path.join(ROOT, "tests/compatibility/index_project.gd.txt"), path.join(driver, "driver.gd"));
    fs.writeFileSync(path.join(driver, "plugin.cfg"),
      '[plugin]\nname="C01 index observer"\ndescription="Test only"\nauthor="Estragon"\nversion="1"\nscript="driver.gd"\n');
    const previous = original.toString();
    const match = previous.match(/\[editor_plugins\]\s*\n([\s\S]*?)(?=^\[|\s*$)/m);
    const enabled = match?.[1]?.match(/^enabled\s*=\s*PackedStringArray\((.*?)\)\s*$/m)?.[1]?.trim() ?? "";
    const plugins = (enabled ? enabled + ", " : "") + '"res://tests/c01_index/plugin.cfg"';
    fs.writeFileSync(configPath, Buffer.concat([original,
      Buffer.from("\n[editor_plugins]\nenabled=PackedStringArray(" + plugins + ")\n")]));
    const stage = await runCommand([sandbox.binary, "--headless", "--path", project, "--editor", ...editorArgs],
      sandbox.workspace, sandbox.env, log, "C01_PROJECT_INDEX_READY", { timeout: 90000 });
    const registry = path.join(driver, "classes.json");
    if (!fs.existsSync(registry)) return { ...stage, status: "FAIL", reason: "Missing indexed class registry" };
    const evidencePath = log.replace(/\.log$/, ".classes.json");
    copyFile(registry, evidencePath);
    const actual = readJSON<Record<string, string>>(registry);
    const mismatch = Object.entries(expected).some(([name, location]) => actual[name] !== location);
    const evidence = { class_registry_sha256: sha256(registry), class_registry_log: path.basename(evidencePath) };
    return mismatch
      ? { ...stage, status: "FAIL", reason: "Incorrect or incomplete class registry", evidence }
      : { ...stage, evidence };
  } finally {
    fs.writeFileSync(configPath, original);
    fs.rmSync(driver, { recursive: true, force: true });
  }
}
export function listGDScripts(folder: string): string[] {
  if (!fs.existsSync(folder)) return [];
  const result: string[] = [];
  const walk = (dir: string): void => {
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, item.name);
      if (item.name === ".godot") continue;
      if (item.isDirectory()) walk(full);
      else if (item.isFile() && item.name.endsWith(".gd")) result.push(full);
    }
  };
  walk(folder);
  return result.sort();
}
export function reportMetadata(): Record<string, unknown> {
  return { schema_version: 1, source_commit: gitHead(), source_dirty: gitDirty(),
    platform: os.platform() + " " + os.release(), collected_at: new Date().toISOString() };
}
