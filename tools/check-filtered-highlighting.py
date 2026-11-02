#!/usr/bin/env python3
"""E01-F real-editor identity research. FAIL remains FAIL under --collect-only."""
import argparse
import datetime
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("compatibility", ROOT / "tools/check-compatibility.py")
compatibility = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compatibility)


def audit(selection, output):
    label, executable = selection.split("=", 1)
    target = output / label
    target.mkdir()
    record = {"label": label, "stages": {}}
    with tempfile.TemporaryDirectory(prefix="estragon-filtered-") as temporary:
        workspace = Path(temporary)
        binary = workspace / "godot"
        shutil.copy2(Path(executable).resolve(), binary)
        record["input_binary_sha256"] = hashlib.sha256(binary.read_bytes()).hexdigest()
        if platform.system() == "Darwin":
            subprocess.run(["/usr/bin/codesign", "--force", "--sign", "-", str(binary)],
                           capture_output=True, check=True)
        (workspace / "_sc_").touch()
        (workspace / "no-tools").mkdir()
        env = dict(os.environ, PATH=str(workspace / "no-tools"), ESTRAGON_EDITOR_TEST="1")
        for key in ["XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"]:
            folder = workspace / key.lower()
            folder.mkdir()
            env[key] = str(folder)
        record["version"] = subprocess.check_output(
            [str(binary), "--headless", "--version"], env=env, text=True, timeout=60).strip()
        manifest = json.loads((ROOT / "tests/compatibility/engines.json").read_text())
        known = next((item for item in manifest if item["version"] == record["version"]), None)
        if not known or (platform.system() == "Darwin" and
                         known["binary_sha256"] != record["input_binary_sha256"]):
            raise ValueError("Engine differs from pinned official provenance")
        record["provenance"] = known.get("official_archive_url", known.get("provenance"))
        project = workspace / "project"
        editor = project / "addons/estragon/editor"
        editor.mkdir(parents=True)
        for name in ["highlighter.gd", "highlighter_association.gd"]:
            shutil.copy2(ROOT / "addons/estragon/editor" / name, editor / name)
        driver = project / "addons/probe"
        driver.mkdir()
        shutil.copy2(ROOT / "tests/editor/compatibility/driver.gd", driver / "base.gd")
        shutil.copy2(ROOT / "tests/editor/filtered/driver.gd", driver / "driver.gd")
        shutil.copy2(ROOT / "tests/editor/seed_plain.gd", project / "seed.gd")
        sources = project / "examples/counter"
        sources.mkdir(parents=True)
        for name in ["Counter.gogo", "Background.gogo", "Counter.gogo.txt"]:
            shutil.copy2(ROOT / "examples/counter/Counter.gogo", sources / name)
        (driver / "plugin.cfg").write_text(
            '[plugin]\nname="E01-F research"\ndescription="Test only"\n'
            'author="Estragon"\nversion="1"\nscript="driver.gd"\n')
        (project / "project.godot").write_text(
            'config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
            '[editor_plugins]\nenabled=PackedStringArray("res://addons/probe/plugin.cfg")\n')
        for phase in [1, 2]:
            name = "phase_" + str(phase)
            stage = compatibility.execute(
                [str(binary), "--headless", "--editor", "--path", str(project)],
                workspace, env, target / (name + ".log"),
                None, timeout=120, abort_on_error=True)
            log = (target / (name + ".log")).read_text()
            # Completion is independent of exact assertion count.
            invariant_ok = stage["status"] == "PASS" and "E01_F_RESULT " in log and \
                any(line.startswith("E01_F_INVARIANTS ") and line.endswith(" PASS")
                    for line in log.splitlines()) and "SCRIPT ERROR:" not in log and "ERROR:" not in log
            stage["status"] = "PASS" if invariant_ok else "FAIL"
            record["stages"][name + "_invariants"] = stage
            record["stages"][name + "_hidden_acceptance"] = {
                "status": "PASS" if invariant_ok and "E01_F_RESULT PASS" in log else "FAIL",
                "identity": [line for line in log.splitlines() if line.startswith("E01_F_IDENTITY ")],
                "observations": [line for line in log.splitlines() if line.startswith("E01_F_HIDDEN_ACCEPTANCE ") or
                                 line.startswith("E01_F_REVEALED_BEFORE_ACTIVATION ")]}
            if not invariant_ok: break
            if phase == 1:
                seed = compatibility.execute(
                    [str(binary), "--headless", "--path", str(project), "--script", "res://seed.gd"],
                    workspace, env, target / "seed.log", "ESTRAGON_SEEDED_PLAIN_RESTORE", abort_on_error=True)
                record["stages"]["seed"] = seed
                if seed["status"] != "PASS": break
    (target / "report.json").write_text(json.dumps(record, indent=2) + "\n")
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--engine", action="append", required=True, help="unique-label=/absolute/godot")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--collect-only", action="store_true", help="collect evidence; never certifies acceptance")
    args = parser.parse_args()
    labels = [item.split("=", 1)[0] for item in args.engine]
    if len(labels) != len(set(labels)) or any(not label or "/" in label or "\\" in label or label in [".", ".."] for label in labels):
        parser.error("engine labels must be unique plain directory names")
    args.output.mkdir(parents=True, exist_ok=False)
    files = [Path(__file__), ROOT / "tools/check-compatibility.py", ROOT / "tests/editor/filtered/driver.gd",
             ROOT / "tests/editor/compatibility/driver.gd", ROOT / "tests/editor/seed_plain.gd",
             ROOT / "addons/estragon/editor/highlighter.gd", ROOT / "addons/estragon/editor/highlighter_association.gd"]
    result = {"source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "source_dirty": bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True)),
              "source_hashes": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
              "platform": platform.platform(), "collected_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "collect_only": args.collect_only,
              "engines": [audit(selection, args.output) for selection in args.engine]}
    (args.output / "results.json").write_text(json.dumps(result, indent=2) + "\n")
    for engine in result["engines"]:
        print(engine["version"], {key: stage["status"] for key, stage in engine["stages"].items()})
    raise SystemExit(0 if args.collect_only or all(stage["status"] == "PASS" for engine in result["engines"]
                                                 for stage in engine["stages"].values()) else 1)


if __name__ == "__main__":
    main()
