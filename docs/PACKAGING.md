# P01 — scoped native addon package preparation

[#104](https://github.com/papercraftgames/Estragon/issues/104) tracks distribution after merged F06 #105 and merged packaging PR #106. GitHub repository transfer and npm organization creation are complete. The owner published the first `@papercraftgames/estragon` beta locally on 2026-11-06 using the verified curated tarball and configured npm Trusted Publisher for the GitHub Actions release workflow. Subsequent OIDC release evidence is recorded on the live workflows. The pending editor beta #117 is deferred until P04 #119 is reviewed and merged; no publication is part of that implementation.

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

Root `package.json` remains private `estragon-tooling`, with existing Bun scripts unchanged. The **actual published GitHub prerelease tag** is the only release-version authority. Git source `addons/estragon/editor/plugin.cfg` uses `0.0.0-dev`; `packages/estragon/package.json` stays unversioned. Git users and plain local packs therefore identify themselves as development checkouts. Installing a tagged npm release gives both npm and Godot metadata the exact tag-derived version, with no source version-bump PR.

When packaging, the packer materializes the deterministic `estragon-tag-overlay-v1` recipe in a temporary stage: replace the single development plugin version and generate the npm manifest with the same validated version. It never edits the checkout. Every other allowlisted file stays byte-identical to reviewed source. Optional standalone native acceptance can independently reconstruct this context and verify direct Yarn installation and Godot metadata, but the release workflow does not run those tests.

An actual release context requires the canonical repository, clean exact event SHA, published non-draft prerelease, strictly formed tag/ref, resolved tag target and reviewed-main ancestry. The verifier binds every file to reviewed source plus those two authorized substitutions, along with tag/release identity, recipe, mode, version and native evidence. Missing or altered overlay data cannot authorize publication. The packer creates a local tarball; it never publishes.

The exact allowlist is all tracked required `addons/estragon/**` (`.gd`, stable `.gd.uid`, `.gd.txt` diagnostic bridge, `.tres`, `.cfg`) plus package README/CHANGELOG/package.json and byte-identical root LICENSE. New file types require explicit review. There are currently no addon-owned raw asset/.import dependencies; supplied Assets are unnecessary and excluded. The full compiler/editor/native runtime/description manager and optional profiling Resources are included. No lifecycle scripts, JS compiler, executable bin, dependencies, tests, examples, raw Assets/screenshots, git internals, .godot, node_modules, .npmrc/secrets or evidence output goes in the tarball.

Packing validates canonical UID uniqueness, plugin path and literal native dependencies; runs `npm pack --dry-run --ignore-scripts --json`; checks exact file membership; packs twice and compares SHA256; unpacks and checks every byte against source. `package-manifest.json` outside the package records clean/dirty source head, exact file hashes, content hash, tar hash, npm integrity/version, overlay context and reproducibility. CI pins npm 11.13.0 for this publishing-tool operation. Yarn remains normal dependency management; no Bun migration is smuggled into packaging.

From a directory outside the root's historical Bun packageManager context:

```sh
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/pack-addon.ts /tmp/new-absolute-addon-package --require-clean
```

This plain command produces a development-version package. Release certification instead supplies the actual event context via `--release-context`; that option cannot accept a release version from an arbitrary CLI argument. Omit `--require-clean` only for truthful development inspection (manifest then records dirty source); release/CI requires clean source. The tool invokes npm pack locally, not registry publication. Same-source repeated pack is checked; do not assume byte identity across arbitrary npm versions. Per-file/content hashes remain the semantic identity and CI pins the pack implementation.

## Yarn-to-Godot install contract

See the standalone [package README](../packages/estragon/README.md).

Installations contain the features of their published tag; the pending E02 editor beta #117 is separate from this implementation. Local reviewed tarball acceptance does not publish registry bytes. Install the current beta in the Godot project root:

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

Each consumer compiles fresh Gogo/typed bool bindings, imports native classes, exercises retained pointer/model updates, deletes generated executables/maps and the editor cache, then actually activates the EditorPlugin through the full configuration path to rebuild before opening the scene, tests saved/unsaved main/current Play rejection/rollback/repair, and renders initial/changed/resized captures. Every package byte/UID remains checked after Godot. Optional standalone certification/consumer tests may run the **direct** layout; the release workflow does not run consumers. The original 3-layout/full suite remains an opt-in regression check. Routine CI remains tiny. Exact outcomes and limitations are recorded on #111/its PR.

Godot's native enabled-plugin loader accepts full resource configuration paths in both [4.0.4](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/editor_node.cpp#L3316) and [4.7](https://github.com/godotengine/godot/blob/4.7-stable/editor/editor_node.cpp#L4114). The [4.0.4 Plugins panel discovery code](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/editor_plugin_settings.cpp) searches addons; that UI discovery boundary does not prohibit full-path activation. Native consumer evidence, rather than source inspection alone, determines acceptance. No engine patch or install-time helper is needed.

## GitHub Release → npm publishing (owner policy, 2026-11-25)

**Release is publishing, not a second test pipeline.** Code checks run during PR/main development and review. Publishing a reviewed GitHub prerelease with a strict `v0.<minor>.<patch>-beta.<iteration>` tag now starts **one `publish` job** in `.github/workflows/npm-release.yml`. No automatic certification, pre-publish Godot test, independent prepare job, native consumer, registry polling, extra result job or step after `npm publish`. The separate `ci.yml` workflows and manually dispatched `certify.yml` remain available for development/optional investigations; they are **not** dependencies of publication.

The release job checks out the actual event source/tag with full history, keeps the canonical-repository and reviewed-main-ancestor/tag/source authorization in `currentContext()`, and builds the tag-versioned addon tarball using `tools/pack-addon.ts --require-clean --release-context`. The packer applies the existing `estragon-tag-overlay-v1` to staged npm and Godot metadata without modifying committed source, and produces the package bytes necessary to publish. These are packaging operations, not a rerun of native UI tests.

The job then runs `npm publish` on that tarball with `--access public --tag beta --provenance --ignore-scripts`, using the existing `npm-publish` environment and `id-token: write` Trusted Publisher/OIDC authorization. **The workflow succeeds when this publish command succeeds and ends immediately.** There is no npm token or fallback publishing path. An npm refusal, including a duplicate immutable version or failed OIDC authorization, is a genuine publication failure; no post-publish verification can turn a successful publication red.

The prior pipeline had `certify → prepare → publish → consumer → result`; this is now **historical only**. In [beta.39 release run 45700419735](https://github.com/papercraftgames/Estragon/actions/runs/45700419735), npm publication succeeded but the subsequent Godot 4.7 consumer hit a transient unavailable registry attestation while 4.0.4 passed. Removing the post-publish gate prevents that class of false-negative release. This change is not retroactive for an already published version; future GitHub releases use the simplified workflow.

### First publication (historical, 2026-11-06)

The owner initially published a reviewed beta locally and subsequently configured the package-specific npm Trusted Publisher for organization `papercraftgames`, repository `Estragon`, workflow `npm-release.yml`, environment `npm-publish`. The npm package already exists; no bootstrap token, second npm account authorization or manual publish is necessary for normal future releases.

### Optional read-only certification

A developer can separately dispatch `ci.yml` with `verification_mode=certification`, a candidate branch and `candidate_tag`. That runs diagnostics and can generate candidate evidence, but **does not gate a release**, does not publish and is not automatically triggered by `npm-release.yml`.

```sh
gh workflow run ci.yml --ref CANDIDATE_BRANCH -f verification_mode=certification -f candidate_tag="$CANDIDATE_TAG"
```

This is optional, not an additional step when publishing.

## P05 — L06 spatial consumer regression

Beta.16 certification stopped before publication on the package fixture's obsolete unscaled numeric3D assertion. P05 [#158](https://github.com/papercraftgames/Estragon/issues/158) verifies the current default100px/world-unit conversion and explicit1 migration in the real installed consumer, with unchanged production API and release gate. [Exact two-engine/full-stage/all-layout proof and recovery](evidence/P05_PACKAGE_SPATIAL.md). The local development-overlay gate is not published-tag certification or publication permission. Do not rerun the old beta.16 workflow expecting new source or move that tag; after review/merge, current-source read-only preview and any new prerelease/tag are owner-controlled.
