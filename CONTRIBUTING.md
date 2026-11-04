# Contributing to Estragon

Estragon is at an experimental design and scaffold stage. Read [VISION.md](docs/VISION.md), [ARCHITECTURE.md](docs/ARCHITECTURE.md) and [DECISIONS.md](docs/DECISIONS.md) before proposing implementation changes.

## Project invariants

- Follow ADR-0015: GGX composes native Nodes; Estragon supplies layout and component semantics while Godot renders. Ordinary Controls are allowed Nodes, not automatic layout participants.
- Migrate the existing RefCounted runtime only through reviewed proof/migration tasks; preserve its current examples.
- Keep the compiler and intermediate representation independent from the renderer.
- Label unimplemented syntax as proposals in docs and examples.
- Prefer compile-time validation and tests over implicit magic or silent fallback.

## Native compilation is the immediate priority

Owner decision ADR-0012: the Godot addon must compile Gogo without requiring users to install Bun, Node or a separate compiler. N01–N03 provide the bundled native parser, generation/parity and editor build gate; no editor subprocess or executable setting remains. Godot-only verification must be independent of Bun; Bun/TypeScript remains optional contributor/CI reference tooling. Follow [the execution plan](docs/EXECUTION_PLAN.md), [N03 / issue #35](https://github.com/resistdesign/Estragon/issues/35) and AGENTS.md.

## Development

```sh
bun install --frozen-lockfile
bun run gogo examples/hello/Main.gogo --output examples/hello/generated/Main.gogo.json
bun run check
```

For the T04 generated surface example, use `bun run transpile examples/compiled/Layout.gogo --output examples/compiled/generated/Layout.gd`; `bun run check` also verifies this fixture. Godot checks regenerate output in an isolated project before importing/running it. See GOGO_LANGUAGE for the supported markup-only subset.

For T05, use `bun run transpile examples/mixed/Mixed.gogo --output examples/mixed/generated/Mixed.gd`; commit the generated code/map and preserve the UID sidecar. GDScript expression validation ultimately comes from Godot, not Bun execution alone.

**Future direction:** Gogo uses TSX-like GDScript-plus-XML-like expressions, unprefixed component tags and generated GDScript. The current namespaced XML-to-JSON compiler is a temporary demo. See [the design direction](docs/DESIGN_DIRECTION.md), and the accepted Gogo-only lowercase `@bindable` decision.

When changing the **stage-0** compiler, update the supported language specification, examples, golden JSON IR and tests. New Gogo-to-GDScript work should generate tests and a runnable Godot proof. When changing graphics behavior, document the backend assumptions and add reproducible smoke-test steps. CI typechecks the TypeScript tooling, runs Bun compiler tests, checks generated IR, and runs Godot 4.7 headless import, script parsing, runtime smoke and harness failure probes. Run `bun run check:godot` and `bun run test:godot-harness` for Godot-facing changes; see [TESTING.md](docs/TESTING.md) for the pinned binary and separate manual visual check.

Planned Codex implementation should follow the work ID, dependency, issue/PR progress and session handoff rules in [AGENTS.md](AGENTS.md), [EXECUTION_PLAN.md](docs/EXECUTION_PLAN.md) and [WORK_STATUS.md](docs/WORK_STATUS.md). The live GitHub issue and PR retain progress between sessions; an unmerged PR is not a completed task.

Pull requests should explain intent, changes, verification, compatibility and whether an architecture decision is affected. Keep speculative features in issues/docs until a functioning prototype demonstrates their viability.

## License

Estragon is licensed under the [MIT License](LICENSE). By contributing, you agree that your contributions will be distributed under this license. Please do not submit third-party assets or source files without confirming redistribution rights.

## Godot metadata and evidence

Commit each real GDScript file with its stable Godot-generated `.gd.uid`, including
compiler, generated examples and tests. Preserve the UID when regenerating or
moving a script. Never copy UIDs from temporary test drivers or unrelated sandbox
files. Commit regular assets' `.import` settings (the five current settings in
`Assets/` remain versioned); `.godot/` is disposable cache. Do not globally ignore
`*.uid` or `*.import`. Godot 4.0.4 uses path-based script references and leaves these
newer sidecars intact; verify with both approved editors when changing this policy. The five real asset
settings have a measured 4.0 normalization difference (newer default fields removed),
so switching engines can modify those tracked files; preserve canonical settings
before unrelated commits. See [exact limitations](docs/NODE_ADAPTER_PROOF.md#metadata-policy-and-audit).
See [Godot's script UID explanation](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
and [import documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/import_process.html).

Archived captures/logs in `tests/compatibility/{b1,b2,b3,c01-h,c61/editor}` are evidence,
not project resources. Each has a narrow `.gdignore`; do not use these paths for
runtime scene assets. Fixture GDScript in neighboring compatibility directories
remains visible. New evidence folders must undergo the same resource/reference
audit before adding a marker. Keep asset UIDs/settings and screenshot import noise
separate in every future issue/PR. `tools/check-godot-metadata.ts` checks metadata
uniqueness, pairing and stable imports in isolated approved-engine editors. Its
explicit `--write-missing-uids` development mode obtains only missing script UIDs
from the pinned 4.7 editor; normal checks never rewrite repository metadata.

C3 native UI: open `examples/native_counter/Counter.tscn` and run the scene with the bundled addon; author `Counter.gogo`. See [native UI contract](docs/NODE_UI.md). Contributor acceptance uses only official 4.0.4 and pinned 4.7.0 on Linux (Xvfb/software graphics); no macOS CI or other-version sweep. Legacy is transitional: C4 removes replaced code, shims and obsolete tests after parity. Do not expand the dual API.
