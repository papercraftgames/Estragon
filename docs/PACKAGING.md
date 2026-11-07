# P01 — scoped native addon package preparation

[#104](https://github.com/papercraftgames/Estragon/issues/104) tracks distribution after merged F06 #105 and merged packaging PR #106. GitHub repository transfer and npm organization creation are complete. The owner published the first `@papercraftgames/estragon` beta locally on 2026-11-06 using the verified curated tarball and configured npm Trusted Publisher for the GitHub Actions release workflow. **The next CI/OIDC release candidate is not yet published.** Keep #104 open until the automated registry/provenance and both public-registry Godot consumer checks pass.

## Retained live scene inventory

All 11 scenes are live and retained. Inspection found no obsolete eager/static binder implementation to delete; deleting useful cases merely to show cleanup would lose coverage. Gogo and generated GD/maps/UIDs are paired and current; the existing audit rejects stale maps, dangling references, duplicate UIDs and retired entrypoints. Historical compatibility/research/report trees marked .gdignore remain archival. Original Assets, license/copyright and author attribution remain unchanged.

| Scene(s) | Supporting source | Native verification |
| --- | --- | --- |
| counter/Counter | Counter.gogo + generated script/map/UID | Native UI runtime/editor/graphics; distribution/cold/pack; fresh npm consumer |
| ggx/TwoD, ggx/ThreeD | Gogo + generated pairs, base.gd/probe_2d.gd/probe_3d.gd | GGX native metadata/runtime/editor/2D+3D graphics and distribution/cold/pack |
| reactive/Demo | Model/State/Demo Gogo + generated pairs | Reactive runtime/editor/graphics and distribution/cold/pack |
| composition/Counter | Model/Counter Gogo + generated pairs | Composition runtime/editor/graphics and distribution/cold/pack |
| conditional/Counter | Child/Counter Gogo + generated pairs | Conditional runtime/rejection/editor/graphics and distribution/cold/pack |
| inventory/Inventory | Item/Row/Inventory Gogo + generated pairs | Keyed runtime/rejection/editor/graphics, profiling and distribution/cold/pack |
| bindable/Demo | Model/Derived/Demo Gogo + generated pairs | Model/class-wide runtime/editor and distribution/cold/pack |
| twoway/Demo | Model/Row/Demo Gogo + generated pairs | Actual pointer/two-way runtime/editor/graphics and distribution/cold/pack |
| node_runtime/TwoD, node_runtime/ThreeD | Authored scenes + demo.gd/UID | Native adapter/core/runtime/editor/graphics; now explicitly included in distribution/cold/pack |

Paths are relative to examples/. No example is shipped inside the npm artifact. Tests are separate consumer fixtures, not a second addon or package. The fresh-consumer proof copies only the canonical authored Counter.gogo/.tscn (no repository generated code/Assets), plus test-only editor/runtime instrumentation. README/current architecture/language/status claims are updated for merged F01–F06. plugin.cfg now describes native compilation instead of Bun. Current public entry links use the transferred repository; historical ADRs/evidence and old issue URLs remain facts with GitHub redirects. No bulk rewrite of historical records or copyright reassignment.

## Artifact contract

Root `package.json` remains private `estragon-tooling`, with existing Bun scripts unchanged. `addons/estragon/editor/plugin.cfg` is the **only committed release-version source**. `packages/estragon/package.json` supplies unversioned scoped public-package metadata, beta dist-tag and MIT license. `tools/pack-addon.ts` reads and validates the plugin version and **generates the npm `package.json` only in its staging directory** before packing. Neither the tracked npm metadata nor documentation duplicates the release version. The initial public beta is already available; changing the plugin version does not authorize publication. The packer creates a local npm tarball; it never publishes.

The exact allowlist is all tracked required `addons/estragon/**` (`.gd`, stable `.gd.uid`, `.gd.txt` diagnostic bridge, `.tres`, `.cfg`) plus package README/CHANGELOG/package.json and byte-identical root LICENSE. New file types require explicit review. There are currently no addon-owned raw asset/.import dependencies; supplied Assets are unnecessary and excluded. The full compiler/editor/native runtime/description manager and optional profiling Resources are included. No lifecycle scripts, JS compiler, executable bin, dependencies, tests, examples, raw Assets/screenshots, git internals, .godot, node_modules, .npmrc/secrets or evidence output goes in the tarball.

Packing validates canonical UID uniqueness, plugin path and literal native dependencies; runs `npm pack --dry-run --ignore-scripts --json`; checks exact file membership; packs twice and compares SHA256; unpacks and checks every byte against source. `package-manifest.json` outside the package records clean/dirty source head, exact file hashes, content hash, tar hash, npm integrity/version and reproducibility. CI pins npm 11.13.0 for this publishing-tool operation. Yarn remains normal dependency management; no Bun migration is smuggled into packaging.

From a directory outside the root's historical Bun packageManager context:

```sh
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/pack-addon.ts /tmp/new-absolute-addon-package --require-clean
```

Omit `--require-clean` only for truthful development inspection (manifest then records dirty source); release/CI requires clean source. The tool invokes npm pack locally, not registry publication. Same-source repeated pack is checked; do not assume byte identity across arbitrary npm versions. Per-file/content hashes remain the semantic identity and CI pins the pack implementation.

## Yarn-to-Godot install contract

See the standalone [package README](../packages/estragon/README.md).

Install the current beta in the Godot project root:

```sh
yarn add --exact --ignore-scripts @papercraftgames/estragon@beta
```

Keep the package where Yarn installs it. Do not copy, symlink or ignore the addon. Before opening the editor, add its full configuration path to the existing `editor_plugins/enabled` list in `project.godot` (preserve other enabled plugins):

```ini
[editor_plugins]
enabled=PackedStringArray("res://node_modules/@papercraftgames/estragon/addons/estragon/editor/plugin.cfg")
```

Godot's Plugins panel discovers candidates under `addons/`; the enabled-plugin project setting accepts a full `res://` configuration path outside that directory. Yarn installation alone does not enable the plugin. Install dependencies before opening Godot; keep only one Estragon tree to avoid duplicate classes/UIDs. Commit the package manifest/lockfile and plugin setting, retaining the package's stable `.gd.uid` sidecars. Godot alone handles editing and Play after installation.

Explicit authored preload aliases reference the chosen installation, for example `preload("../../../node_modules/@papercraftgames/estragon/addons/estragon/runtime/composition/element.gd")` in a Gogo file whose generated script lives three directories below the project root. As with ordinary GDScript, relative authored imports resolve from the **generated script's directory**. Canonical registered widget class names also work after Godot indexes the project. Internal dependencies are script-relative; compiler-injected dependencies are calculated from installed Resources and the actual output directory. A different project-relative installation needs only matching authored imports and the plugin configuration setting; no production source edits. Standard `addons/estragon` placement remains supported.

Author `.gogo` files and normal `.tscn` hosts referencing generated scripts. Optional `gogo.config.json`: `{"version":1,"source_roots":["src"]}`. Native save and main/current Play compile with actual-path validation, invalid/unsavable-source rejection, rollback and repair. Generated files must be rebuilt after relocating an installed addon, just as authored imports must be updated.

P02 [#111](https://github.com/papercraftgames/Estragon/issues/111) replaces the former copy-based consumer contract. `tools/check-package.ts` keeps seven required stages (pack/install/build/import/runtime/editor/visual), with separate direct, nonstandard relocated and standard consumer runs inside each native stage. The direct consumer uses Yarn's untouched `node_modules` package, with no ignored tree, copied addon, symlink or repository fallback. The relocation cases move the single installed addon before import. Test-only fixtures configure authored imports for their chosen locations; package scripts and generated outputs are never rewritten.

Each consumer compiles fresh Gogo/typed bool bindings, imports native classes, exercises retained pointer/model updates, deletes generated executables/maps and the editor cache, then actually activates the EditorPlugin through the full configuration path to rebuild before opening the scene, tests saved/unsaved main/current Play rejection/rollback/repair, and renders initial/changed/resized captures. Every package byte/UID remains checked after Godot. Full certification and both post-publication registry consumers invoke this same contract; routine CI remains tiny. Exact outcomes and limitations are recorded on #111/its PR.

Godot's native enabled-plugin loader accepts full resource configuration paths in both [4.0.4](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/editor_node.cpp#L3316) and [4.7](https://github.com/godotengine/godot/blob/4.7-stable/editor/editor_node.cpp#L4114). The [4.0.4 Plugins panel discovery code](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/editor_plugin_settings.cpp) searches addons; that UI discovery boundary does not prohibit full-path activation. Native consumer evidence, rather than source inspection alone, determines acceptance. No engine patch or install-time helper is needed.

## GitHub Release → npm publishing

The implementation follows the owner's working [Voltra workflow](https://github.com/resistdesign/voltra/blob/87814e2f6451ef224812f4eac44eb402c0c31b9e/.github/workflows/release-npm.yml) (blob `ce143f7ed2c50cd9765d8de22e9eed79c1b52491`): `release: types: [published]`, GitHub-hosted Ubuntu, Node24, registry URL, `npm-publish` environment and isolated `contents: read` / `id-token: write`. Voltra's YAML supplies no npm publishing token; its successful publication is owner-confirmed. This does not expose hidden npm trust settings or transfer trust to another package/repository.

After the plugin-version PR is reviewed and merged, the normal release action is **publish a GitHub prerelease tagged `v` plus the version in `addons/estragon/editor/plugin.cfg`, from the reviewed main commit**. The current bounded release policy accepts `0.x.y-beta.n` only and always uses npm `beta`, never `latest`. Version changes must be reviewed on main first. The GitHub Release is deliberate publication authorization; there is no second dispatch, version input, CI-run-ID entry, artifact transfer, repository enable flag or mandatory second environment approval. Owners may choose environment protection separately; none is prescribed here. Optional `workflow_dispatch` is read-only preview and can never publish.

The workflow resolves the checked-out tag to a clean reviewed-main commit, derives the version from plugin.cfg and rejects draft/non-prerelease, mismatched tag/version/source or foreign repository. Before preparation/publishing, certify.yml must execute all73 stages on both approved Linux engines at that exact SHA. tools/verify-npm-release.ts requires two successful current-run certification jobs and independently verifies every source/engine/log hash, UID/payload contract, both identical reproducible tarballs, tar members and unpacked bytes. Routine main CI is fast sanity only and cannot authorize publication. Missing, failed, cancelled, stale or mismatched certification fails closed; only the actual tested tarball may be published. The old main-CI discovery/wait loop is removed. Read-only branch certification previews exercise the same full gate before review, without any publication permission.

Preparation uploads `approved-npm-package` with `release-ready.json`, version, source, original verification run, file/content/tar hashes, integrity and release identity. Only the release-event publish job has OIDC write permission, Node24/npm11.21.2 and the `npm-publish` environment. Existing packages use tokenless OIDC to publish that **exact tarball**, public/beta/provenance. A denial does not fall back to bootstrap credentials. Re-running after a partial failure verifies an existing exact version instead of trying to publish it again or replacing bytes.

Publication checks the registry version, beta tag, absence of that version on latest, integrity and attached provenance. Two post-publish Linux jobs independently fetch the public tarball, compare SHA256/SHA512 with the tested tarball, retain its registry SLSA provenance bundle, install the exact registry version using Yarn in a new cache/project and run all seven native consumer stages (build/import/runtime/editor/rendered proof included). Installed file hashes must match the reviewed manifest. No registry compiler/tooling dependency is introduced. A final result job requires certification, preparation, publication **and both native consumer jobs** to succeed. Summary and artifacts record failures too. Registry publication is irreversible even if a later smoke fails: the run remains failed/incomplete; fix verification and rerun the same release jobs, never substitute different bytes under that version.

### First publication and Trusted Publisher status (2026-11-06)

The owner authenticated the existing npm CLI and published the exact reviewed initial-beta tarball locally using `npm publish <tarball> --access public --tag beta --ignore-scripts`. Its package SHA-256 matched prior two-engine CI evidence: `52a30255edd7339117e80e507a6de175d08c7a999873ae3dc422f892545f0f6f` (88 files, 40 canonical Godot script UIDs). That initial manual publication did not claim GitHub Actions OIDC provenance.

The owner then added a package-specific npm Trusted Publisher for organization `papercraftgames`, repository `Estragon`, workflow `npm-release.yml`, environment `npm-publish`, with the **Allow npm publish** permission. The npm UI reports **Pending validation** until a successful OIDC CI publication. Do not request a new account association, a temporary npm token or staged first-package creation: **the npm package exists and the first release was already published.** The dormant absent-package bootstrap branch in the existing workflow is no longer needed for releases of this existing package.

After the owner merges the plugin-version PR, publishing the reviewed GitHub prerelease with tag `v` plus the canonical plugin version starts the existing automatic release workflow. Mandatory current-run two-engine certification and independent preparation must validate the exact reviewed source and tested tarball before publication. Publishing must use package-specific OIDC trust; the registry must show the approved beta with exact integrity and matching provenance. Fresh registry Yarn-to-Godot consumers on **both** official Linux 4.0.4 and pinned 4.7.0 must pass before #104 can close. A PR merge alone is not publication authorization; no GitHub Release or actual publish is performed in this version-source PR.

## Evidence, limits and remaining work

Live #104/sole PR records exact commands, clean source/engine hashes, artifact digests, failures/repairs, counts, inspected captures and final handoff. Only official Linux Godot 4.0.4 and pinned4.7.0; other platforms/minors untested. Manual interactive 4.7 smoke status is reported separately; physical F5/F6 is not a gate. The current #44 highlighter and documented older-engine diagnostic/introspection limitations remain. Pre-1.0 UI scope excludes richer text/IME/focus/themes/accessibility and the separately tracked layout/editor/release roadmap. The initial local beta is public; automated trusted-publisher validation and final registry/native acceptance remain separate owner-triggered actions, not inferred completion of #104.
