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

## Manual release preparation and trusted publishing

The GitHub/npm organizations exist, but no per-package publisher, package creation, reviewer environment or publication permission is claimed configured. npm's current [trusted-publisher documentation](https://docs.npmjs.com/trusted-publishers/) specifies Node ≥22.14/npm ≥11.5.1, GitHub-hosted runners, exact repository/workflow identity and `id-token: write`. Package settings are where a publisher is bound; initial package creation may require an owner-authenticated first publish. OIDC from a public repository/public package supplies provenance. Verify current official docs at release time; no long-lived write token belongs in this repo.

Prepared workflow `.github/workflows/npm-release.yml` has **workflow_dispatch only**, preview by default, no merge/tag/release trigger. Its preparation job accepts an exact version and successful existing **canonical main push** `ci.yml` run ID, then `tools/verify-npm-release.ts` checks repository, branch/event, source SHA, clean tree, version, full two-engine reports/hash/provenance and both identical already-tested package tarballs against reviewed source bytes. It reuses CI evidence rather than scheduling duplicate engines. A preview produces an approved artifact and `release-ready.json`, and has no publish permission.

Publishing additionally requires `publish=true`, repository variable **NPM_PUBLISH_ENABLED=true**, canonical main and protected environment **npm-release**. These controls are owner setup; they are not enabled here. Only that job gets OIDC write permission. It verifies the selected tar digest/source again and invokes `tools/publish-prepared.ts`; a future authorized publish uses the exact tested tarball, public access/beta tag/provenance, then Yarn fetch + npm registry version/provenance inspection. This job has **not run**. Package/organization settings and actual registry writes cannot be proven by inspecting workflow YAML.

### Owner's first-release sequence (not executed)

1. Review/merge this PR. Choose/authorize the exact initial version and beta tag separately. If changing the proposed manifest version, update/review it and wait for full two-engine main CI; don't relabel an untested tarball.
2. Protect GitHub environment `npm-release` with required owner reviewers and branch restrictions before enabling publication. Keep NPM_PUBLISH_ENABLED unset/false until setup is complete. Confirm npm organization publish access/2FA in the owner's account. No secrets are added by this implementation.
3. Run release workflow **preview only** on main with that exact successful main CI run ID/version. Inspect its tarball, hashes, content manifest and acceptance; resolve any fail-closed mismatch. This step performs no npm publication and is suitable for reviewing the concrete proposed release.
4. If npm has no package settings yet, after explicit publication approval use the reviewed tarball from step 3 with the owner's authenticated npm session: `npm publish /absolute/approved.tgz --access public --tag beta --ignore-scripts` (owner completes required 2FA). Do not create a token or pretend a manual first publish has OIDC provenance. Verify npm registry version/integrity against the approved manifest and Yarn fetch/file-placement/Godot smoke before claiming release success. If the registry permits bootstrap OIDC configuration instead, use it only after confirming the actual package settings/permissions; not assumed here.
5. Configure the package's trusted publisher with organization **papercraftgames**, repository **Estragon**, workflow filename **npm-release.yml**, environment **npm-release**, following current npm UI/docs. The fields are exact/case-sensitive. For a later separately approved version, enable the repository flag and explicitly dispatch publish mode, then approve the protected environment. No duplicate publish of the first version. Check automatic provenance and the post-publish smoke; keep issue #104 open until actual publication/verification is recorded.

No workflow/account configuration, public tag/release or npm publish is performed as part of this PR. The reserved `estragon.papercraft.games` site and existing PaperCraft Games website are untouched.

## Evidence, limits and remaining work

Live #104/sole PR records exact commands, clean source/engine hashes, artifact digests, failures/repairs, counts, inspected captures and final handoff. Only official Linux Godot 4.0.4 and pinned4.7.0; other platforms/minors untested. Manual interactive 4.7 smoke status is reported separately; physical F5/F6 is not a gate. The current #44 highlighter and documented older-engine diagnostic/introspection limitations remain. Pre-1.0 UI scope excludes richer text/IME/focus/themes/accessibility and the separately tracked layout/editor/release roadmap. Packaging preparation is reviewable and verified; public release remains a separate owner action, not an inferred completion of #104.
