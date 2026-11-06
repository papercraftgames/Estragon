# P01 — scoped native addon package preparation

[#104](https://github.com/papercraftgames/Estragon/issues/104) prepares distribution after F06 #105 merged (`55156fb`). GitHub transfer to `papercraftgames/Estragon` and npm organization/scope creation are owner-confirmed complete. **No npm publication, public version tag/release, website change or merge is performed by this task.** The issue remains open until a separately authorized initial release is verified.

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

Root `package.json` remains private `estragon-tooling`, with existing Bun scripts unchanged. `packages/estragon/package.json` supplies **only** scoped public-package metadata, proposed version `0.1.0-beta.1`, beta dist-tag and MIT license. This version is a review candidate, not permission to publish it. `tools/pack-addon.ts` creates a new absolute staging directory and local npm-format tarball; it never publishes.

The exact allowlist is all tracked required `addons/estragon/**` (`.gd`, stable `.gd.uid`, `.gd.txt` diagnostic bridge, `.tres`, `.cfg`) plus package README/CHANGELOG/package.json and byte-identical root LICENSE. New file types require explicit review. There are currently no addon-owned raw asset/.import dependencies; supplied Assets are unnecessary and excluded. The full compiler/editor/native runtime/description manager and optional profiling Resources are included. No lifecycle scripts, JS compiler, executable bin, dependencies, tests, examples, raw Assets/screenshots, git internals, .godot, node_modules, .npmrc/secrets or evidence output goes in the tarball.

Packing validates canonical UID uniqueness, plugin path and literal native dependencies; runs `npm pack --dry-run --ignore-scripts --json`; checks exact file membership; packs twice and compares SHA256; unpacks and checks every byte against source. `package-manifest.json` outside the package records clean/dirty source head, exact file hashes, content hash, tar hash, npm integrity/version and reproducibility. CI pins npm 11.13.0 for this publishing-tool operation. Yarn remains normal dependency management; no Bun migration is smuggled into packaging.

From a directory outside the root's historical Bun packageManager context:

```sh
corepack yarn@1.22.22 node --experimental-strip-types /absolute/Estragon/tools/pack-addon.ts /tmp/new-absolute-addon-package --require-clean
```

Omit `--require-clean` only for truthful development inspection (manifest then records dirty source); release/CI requires clean source. The tool invokes npm pack locally, not registry publication. Same-source repeated pack is checked; do not assume byte identity across arbitrary npm versions. Per-file/content hashes remain the semantic identity and CI pins the pack implementation.

## Yarn-to-Godot install contract

See the standalone [package README](../packages/estragon/README.md). In a fresh Godot project:

```sh
yarn add --exact --ignore-scripts file:/absolute/papercraftgames-estragon-0.1.0-beta.1.tgz
touch node_modules/.gdignore
mkdir -p addons
cp -R node_modules/@papercraftgames/estragon/addons/estragon addons/estragon
```

After an approved public version exists, its scoped exact-version Yarn command can replace the local-tarball command. `addons/estragon` must not already contain another version; deliberate upgrade replacement/backups are required. Ignore node_modules in Godot to avoid duplicate script classes/UID import. Use a copy, not a source/output symlink. Enable Project Settings → Plugins → **Estragon** at `res://addons/estragon/editor/plugin.cfg`. Neither Yarn installation nor the copy silently registers it. Source/output validation intentionally rejects symlinks. Commit the copied addon/UIDs; the finished Godot project needs no Node/Bun/Yarn at editing or Play time.

Optional project config: `{"version":1,"source_roots":["src"]}` in `gogo.config.json`. Normal native save/main/current Play supplies deterministic generated scripts/maps, actual-path semantic validation and transactional rollback/repair. Canonical widget tags or explicit preload aliases retain their existing contracts. This is not a JavaScript module or a Godot Control wrapper.

`tools/check-package.ts` exercises this exact route in an isolated real consumer: local dry-run/pack/hash audit → offline local-tar Yarn acquisition with scripts disabled → explicit ignore/copy → fresh native source build/import → actual pointer/runtime → real saved/unsaved main/current editor invalid/unsavable rejection+repair → rendered initial/changed/resize proof. Installed addon bytes/UIDs must remain identical after import/Play. PATH has no external compiler for Godot stages. These seven stages add to all F06 66 required native-addon stages; none is removed.

## GitHub Release → npm publishing

The implementation follows the owner's working [Voltra workflow](https://github.com/resistdesign/voltra/blob/87814e2f6451ef224812f4eac44eb402c0c31b9e/.github/workflows/release-npm.yml) (blob `ce143f7ed2c50cd9765d8de22e9eed79c1b52491`): `release: types: [published]`, GitHub-hosted Ubuntu, Node24, registry URL, `npm-publish` environment and isolated `contents: read` / `id-token: write`. Voltra's YAML supplies no npm publishing token; its successful publication is owner-confirmed. This does not expose hidden npm trust settings or transfer trust to another package/repository.

After review/merge and one-time setup below, the normal release action is **publish a GitHub prerelease named exactly `v<packages/estragon/package.json version>` from the reviewed main commit**. The current bounded release policy accepts `0.x.y-beta.n` only and always uses npm `beta`, never `latest`. Version changes must be reviewed on main first. The GitHub Release is deliberate publication authorization; there is no second dispatch, version input, CI-run-ID entry, artifact transfer, repository enable flag or mandatory second environment approval. Owners may choose environment protection separately; none is prescribed here. Optional `workflow_dispatch` on main is read-only preview and can never publish.

The workflow automatically resolves the checked-out tag to a clean commit reachable from current main and rejects draft/non-prerelease, mismatched version/tag/source or foreign repository. `tools/verify-npm-release.ts` discovers the newest exact-source **main push** `ci.yml` run and waits up to30minutes if absent/incomplete. A failed latest run is rejected rather than selecting older green evidence. It authenticates the run identity and every log/source/engine hash, requires all73 stages on both approved engines and both identical tested tarballs, then checks exact tar members and unpacked bytes against reviewed source. No version rewriting or repacking replaces the tested artifact. Retained evidence may expire: if exact-source artifacts are unavailable, fail closed and restore exact-source CI evidence before release; never use another commit's evidence.

Preparation uploads `approved-npm-package` with `release-ready.json`, version, source, original verification run, file/content/tar hashes, integrity and release identity. Only the release-event publish job has OIDC write permission, Node24/npm11.21.2 and the `npm-publish` environment. Existing packages use tokenless OIDC to publish that **exact tarball**, public/beta/provenance. A denial does not fall back to bootstrap credentials. Re-running after a partial failure verifies an existing exact version instead of trying to publish it again or replacing bytes.

Publication checks the registry version, beta tag, absence of that version on latest, integrity and attached provenance. Two post-publish Linux jobs independently fetch the public tarball, compare SHA256/SHA512 with the tested tarball, retain its registry SLSA provenance bundle, install the exact registry version using Yarn in a new cache/project and run all seven native consumer stages (build/import/runtime/editor/rendered proof included). Installed file hashes must match the reviewed manifest. No registry compiler/tooling dependency is introduced. A final result job requires preparation, publication **and both native consumer jobs** to succeed. Summary and artifacts record failures too. Registry publication is irreversible even if a later smoke fails: the run remains failed/incomplete; fix verification and rerun the same release jobs, never substitute different bytes under that version.

### One-time first-package bootstrap (not executed)

GitHub/npm organizations, 2FA and npm–GitHub account linking already exist. Do not repeat those steps. The [npm trust prerequisites](https://docs.npmjs.com/cli/v11/commands/npm-trust/) require an existing registry package. Therefore Voltra's package-specific OIDC binding cannot simply create this new scoped package. Current [npm staged publishing](https://docs.npmjs.com/staged-publishing/) and [npm-stage token rules](https://docs.npmjs.com/cli/v11/commands/npm-stage/) support a CI-orchestrated first creation with a granular token **without bypass2FA**, deferring owner2FA to approval. Staging a new package creates a **public `0.0.0-stage` placeholder** before the real version is approved; staging itself requires explicit publication authorization. npm≥11.15 supports this flow; publishing uses pinned11.21.2, while tested packing remains pinned11.13.0.

Owner-only checklist, once after this PR is reviewed/merged and the exact first release is authorized:

1. Supply a short-lived granular credential with minimum package-creation permission in the `@papercraftgames` scope and **no bypass2FA**, as environment secret `NPM_BOOTSTRAP_TOKEN` in `npm-publish`. An existing suitably restricted authorized credential may be reused; never copy another package's trust configuration or broaden a permanent token. Confirm the actual account can create packages in this scope; this PR does not inspect/change hidden account permissions. No secret is needed for later OIDC releases.
2. Publish the approved GitHub prerelease from reviewed main. The same workflow discovers CI and stages the exact tested tarball only if npm returns404 for the package. Other lookup errors fail closed. The token is supplied only to `npm stage publish`; it is removed from direct publishing/verification. The job logs the staged result and waits up to60minutes for approval; it does not report publication success while waiting.
3. In npm's **Staged Packages** UI, inspect the CI staged version and approve it with existing owner2FA. No local publish, tarball transfer or second workflow dispatch. Once the placeholder/package exists, bind trusted publisher to **papercraftgames / Estragon / npm-release.yml / npm-publish**, allowing direct publish, then revoke the temporary credential and delete its GitHub secret. These are package-specific one-time settings; exact trust is not claimed configured here. Public release evidence must include attached provenance and both registry consumer jobs before closing #104.

If approval exceeds the wait, the job fails clearly. Approve the existing staged version and rerun the existing release jobs; placeholder-only packages wait for approval, not a second staging or direct publish attempt. Once a real version exists, every subsequent GitHub Release uses OIDC automatically, even if an obsolete bootstrap secret was accidentally left configured. There is no permanent/broad-token fallback. Missing trust remains a real release failure.

No release workflow, stage/publish command, package/publisher/secret/environment setting, public tag/release or merge is executed as part of this correction. Actual bootstrap permissions, OIDC trust, registry publication/provenance and registry→Godot execution remain untested until separately authorized. Local policy tests simulate these branches without registry writes; pre-publication CI still exercises all73 stages per engine against identical local packed bytes. The reserved website remains untouched.

## Evidence, limits and remaining work

Live #104/sole PR records exact commands, clean source/engine hashes, artifact digests, failures/repairs, counts, inspected captures and final handoff. Only official Linux Godot 4.0.4 and pinned4.7.0; other platforms/minors untested. Manual interactive 4.7 smoke status is reported separately; physical F5/F6 is not a gate. The current #44 highlighter and documented older-engine diagnostic/introspection limitations remain. Pre-1.0 UI scope excludes richer text/IME/focus/themes/accessibility and the separately tracked layout/editor/release roadmap. Packaging preparation is reviewable and verified; public release remains a separate owner action, not an inferred completion of #104.
