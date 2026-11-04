# C4 native-addon acceptance

ADR-0015-C4 #83 / PR #84 retires the parallel RefCounted UI, stage-0 JSON/reference compilers and proof/shim paths. The current evidence represents the canonical native addon, not renamed historical results.

Acceptance uses official Godot 4.0.4 (`fc0b241c9`) and pinned 4.7.0 (`5b4e0cb0f`) on Linux only. The complete artifact contains exact-source/engine provenance, hashed logs/results, native compiler/runtime/GGX/UI/editor/metadata/distribution checks, real graphics captures and the strict native-addon release assessment. No external compiler in native process PATH; no standalone executable product requirement.

Product-relevant fixes measured during C4:
- Native startup compiles eagerly before missing-generated scene restoration, without waiting for a specific runtime class. This fixes fresh source-only Counter restoration on 4.0.4; actual-path semantic validation/cache rollback remain mandatory.
- Resource-pack fixture uses a valid Linux x86_64 preset and includes native sample script dependencies explicitly.
- Godot 4.0.4 text-to-binary scene conversion leaks its instantiated scene roots. The sample explicitly uses the supported `editor/export/convert_text_resources_to_binary=false` path, with real editor `--export-pack` and separate bare-process native scene runtime. No native error is filtered/waived and binary-conversion export is not claimed fixed. See [official engine source](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/export/editor_export_platform.cpp#L742) and docs/TESTING.md.

Historical failures are preserved under earlier evidence roots and issue #65. Existing-instance inherited-default initialization remains observed BLOCKED in the native publication probe; running-application hot reload is not a promised product behavior. Fresh defaults/current bytecode/Script identity/state preservation remain mandatory assertions.

No manual interactive Godot 4.7 smoke session ran. Automated actual native editor/game checks and real Mesa/OpenGL captures ran; graphics are inspected separately from headless assertions. No physical-key test, extra engine or untested-platform/minor certification. No automatic publishing/merge or successor task.

Focused native distribution bridge verification: [official 4.0.4 Linux run 41888341607](https://github.com/resistdesign/Estragon/actions/runs/41888341607) PASS for package/import, native scenes, source-only build/runtime, cold editor restore, actual editor export and bare-process runtime. Its exact engine/source/commands/results and logs are preserved in `focused-4.0.4/`; this is focused distribution proof, not full-addon release certification. Final full matching two-engine results/graphics and current-head verdict are recorded on [#83](https://github.com/resistdesign/Estragon/issues/83) / [PR #84](https://github.com/resistdesign/Estragon/pull/84). C4 remains In review until owner merge.
