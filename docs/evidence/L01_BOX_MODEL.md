# L01 — shared native Box and pixel box model

Issue [#55](https://github.com/papercraftgames/Estragon/issues/55), base merged L05#152 `de6638a`. Production implementation and full editor proof are clean **`3c6b76b68cda3b8084be664ac7ed41b053828cf2`**. Final test-only native Container refinement is clean **`b261b6b`**; production/package bytes are identical. This is local review evidence, not release certification. L01 remains In review until owner merge.

## Implemented contract and native proof

[Public semantics](../NODE_UI.md#l01--pixel-box-model), [runnable source](../../examples/box_model/BoxModel.gogo) and [scene](../../examples/box_model/BoxModel.tscn). EstragonBox is a constructible horizontal native base shared by HBox/VBox and Entry2D. Box owns common padding; axes differ only in HBox/VBox. Component2D owns outer margins, including leaves. Every active component remains one real Node2D, using the existing coordinator and pure layout core. No retired Container/Stack, renderer, alternate layout engine or compatibility path returns.

Explicit dimensions include padding and exclude margin. Auto adds content, gaps, child margins and own padding once; fixed bounds constrain content availability; fill reserves margins/gaps before sharing the remaining nonnegative content space. Native minimum floors remain authoritative. Too-small content clamps at zero and fixed/minimum children overflow sequentially. Cross alignment stays leading and center operates on the whole outer row. Native geometry/paint/input use the same inset-adjusted transforms. Nested Gogo host proxies forward a root margin once and arrange its root at local zero.

Per-edge overrides beat scalar shorthand independently of assignment/attribute order, including zero. Native exported edges use -1 as unset/reset-to-shorthand, preserving the distinction through PackedScene; GGX insets accept only nonnegative finite numeric values. Width/height additionally accept quoted numeric pixels and auto. Unsupported percent/unit strings and obvious invalid lengths produce authored diagnostics. Existing description preflight checks dynamic domains before writes; invalid data does not partially apply a desired tree. Text/UiButton intrinsic text padding, native Control API/Container interior authority and 3D world-unit contracts stay bounded as documented.

## Fresh direct-Yarn acceptance

Only official Linux **4.0.4.stable.official.fc0b241c9** and pinned **4.7.stable.official.5b4e0cb0f** were run. Authenticated input hashes and exact commands are in each provenance file. Both engines consume the same reproducible development tar **`bb9b8c7040ead9dfe2556c5ae78e4c22b79f124bccb85c6493ee81d20df16eab`**, directly from node_modules without copied/symlinked/ignored addon payload. All **58** packaged UID sidecars/installed bytes remain unchanged through build, native editor, game and restart. [4.0.4 manifest](l01/acceptance/4.0.4/package-manifest.json), [4.7 manifest](l01/acceptance/4.7/package-manifest.json).

| Engine | Full runtime checks | Editor / restart checks | Build / runtime / editor / restart wall |
| --- | --- | --- | --- |
| 4.0.4 | 64 PASS | 5 / 2 PASS | 2.17 / 7.75 / 29.25 / 16.61 seconds |
| 4.7.0 | 64 PASS | 5 / 2 PASS | 1.41 / 4.40 / 18.49 / 11.75 seconds |

Full two-engine runner: **106.28s**, separate from routine CI's 60-second budget. [4.0.4 results](l01/acceptance/4.0.4/results.json), [4.7 results](l01/acceptance/4.7/results.json). Native checks cover asymmetric edges, shorthand precedence, padded Entry/Box/HBox/VBox, nested auto/fixed/fill, clamp/overflow/center, actual red painted pixels, precise UiButton pointer hit/miss, reactivity/retained identity, cached clean siblings, idle/equal/invalid writes, coalesced bursts, scene-pack explicit-zero edges, native detach/re-entry, pre-refactor zero-inset geometry, current Counter and the interactive Box example. Invalid source keeps valid generated Script/maps/cache identity, and repair recovers.

The real isolated editor shows inherited `padding_left — float` completion in unchanged valid Gogo, builds installed imports/maps, runs actual current/main games and restarts. Child game proof records button **(39,35), width180, padding20, clicks1** after a bindable padding change. No physical keypress was required. 4.0.4 optional isolated-preflight/symlink introspection remains **BLOCKED/unavailable**; mandatory transactional actual-path validation succeeds. No weaker older-engine path or product minimum change was introduced.

Final review added three runtime checks for ordinary native HBoxContainer integration: reserve sibling margins before native flex, preserve Container child sizing/ownership, and retain an 80-pixel native minimum when a padded content box has only 80 pixels for it plus a sibling's outer30. Only runtime/build/install proof was repeated; unchanged editor/production bytes were not rerun. Final **67 checks PASS per engine** at `b261b6b`, with identical package tar and preserved58 UIDs. [4.0.4 final results](l01/containers/4.0.4/results.json), [4.7 final results](l01/containers/4.7/results.json); 6.50/4.30s runtime, **25.98s** whole focused follow-up.

![Actual runnable Box model example after clicking Change padding](l01/acceptance/4.7/example.png)

[Before](l01/acceptance/4.7/before.png), [after reactive padding](l01/acceptance/4.7/after.png), [actual editor game](l01/acceptance/4.7/editor-game.png), [Counter](l01/acceptance/4.7/counter.png), [native Container overflow](l01/containers/4.7/native-container.png). Captures and corresponding geometry/pointer assertions were inspected; these are native rendered frames, not headless visual claims.

## Proportional regressions and source checks

- Existing approved4.7 `check-node-runtime.ts --graphics`: **18 core +147 runtime**, both native persistence editor passes and rendered 2D/3D providers/lifecycle stages PASS, **32.50s**. [Results](l01/regression-4.7/results.json). This preserves plain boundaries, explicit Entries, native removal/reparent/free, pack/reopen and 3D zero-inset defaults.
- Existing `check-compatibility.ts` on both approved engines: import + frontend (**70 assertions each**) + registered/positive/rollback/fresh-failure publication stages PASS, **26.34s** total. [4.0.4](l01/compiler/4.0.4/results.json), [4.7](l01/compiler/4.7/results.json). The two intentionally invalid publication cases retain exactly their expected native diagnostic; no unexpected errors/leaks are exempted.
- `bun install --frozen-lockfile && bun run check`: TypeScript typechecking and **30 policy tests PASS** ([log](l01/static.txt)). Canonical source audit: **170 scripts/170 unique paired UIDs**, archival research excluded ([audit](l01/uids.txt)). New sidecars are stable canonical-path IDs, preserved by native import; none were copied from temporary runner identities. Isolated official4.7 native build produced checked-in BoxModel GDScript/maps ([build](l01/example-build.txt)). No shared-checkout editor settings/plugin preference was changed.

No Assets, release/version/tag/workflow/account/publication changes. No full73, extra engines/platforms or manual interactive/macOS Godot4.7 smoke was run. Percentages/units#54, general positions#88, native Control custom margins/padding, configurable text padding, broader styles/wrapping/alignment and 3D pixel conversion remain out of scope.

## Corrected development attempts

Initial static checks failed while new addon scripts/sidecars were untracked/missing; after canonical IDs and tracking, all30 policies pass. Early runtime fixture attempts used an inferred Variant string, called Script metadata on a class without casting/instance, and loaded in-memory generated code at a path inconsistent with its relative imports. These harness errors were corrected before clean acceptance; all production native layout/paint assertions were already correct. Final runners fail closed for every unexpected error/leak. No error allowlist was added to the L01 runner. Docker's inherited-environment startup EOF was resolved with a shorter inherited PATH; no Docker update/settings edit was used.

## Exact reproduction

Owner-approved local Docker `estragon-e04-local`, image `estragon-p02-linux-env:local`; repository mounted read-only `/repo`, authenticated engines `/engines`, host `/tmp/e04-local` mounted `/evidence`. Xvfb/Openbox/Mesa graphics and sandbox self-contained settings; compiler/game PATH contains no external compiler. Logs normalize trailing whitespace and rename .log to .txt; stage records preserve the original commands/log names. [SHA-256 artifact index](l01/artifact-index.json).

```sh
bun install --frozen-lockfile
bun run check
node --experimental-strip-types --input-type=module -e 'import {auditNativeSource} from "./tools/audit-native-source.ts"; console.log(JSON.stringify(auditNativeSource()));'
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/l01-accept-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-box-model.ts --editor --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/l01-accept'
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/l01-containers-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-box-model.ts --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/l01-containers'
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/l01-regression-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-node-runtime.ts --graphics --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/l01-regression'
docker exec -w /tmp estragon-e04-local corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-compatibility.ts --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/l01-compiler
```

Use a new absolute output directory per run. Issue/sole PR handoff records final branch/head/base, exact required CI and owner-review next action. No publication, release certification or merge is authorized by this evidence.
