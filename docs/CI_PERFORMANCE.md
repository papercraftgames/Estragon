# CI01 / CI02 — PR/main checks and optional native certification

[CI01 #109](https://github.com/papercraftgames/Estragon/issues/109) keeps required PR/main checks within a **60-second execution-wall budget**. CI02 #113 originally reduced automatic release testing; its historical evidence remains, but the owner revised the release contract on November 25, 2026: **the release workflow now only publishes**.

## PR/main checks

`ci.yml` runs frozen static/policy checks and, for code changes, a small Godot 4.7 headless native smoke. It does **not** run the complete product acceptance matrix on every merge. More extensive native/editor/graphics checks are performed as needed during development, on focused branches, and as optional manual verification; do not claim the tiny routine check is equivalent to full native certification. Required PR/main checks and branch protection are unchanged by the publishing simplification.

## Publishing has no test stages

The owner-published prerelease triggers **one publish job** in `.github/workflows/npm-release.yml`. It checks out the tagged reviewed-main source, creates the tag-versioned npm/Godot addon tarball with the existing reproducible packer, then invokes Trusted Publisher/OIDC `npm publish`. **Publishing is the final operation and determines the workflow result.** It does not call `certify.yml`, `verify-npm-release.ts`, an installed Yarn consumer, native Godot, registry provenance polling or a post-publish result gate.

The prior `certify → prepare → publish → consumer → result` chain is historical. It caused [release beta.39](https://github.com/papercraftgames/Estragon/actions/runs/45700419735) to be marked failed after npm had already published successfully because one subsequent registry-attestation read failed. Future publication runs do not repeat that mistake.

## Optional focused native verification

`certify.yml` and `ci.yml`'s manual read-only `verification_mode=certification` are retained for deliberately requested acceptance on official Linux Godot 4.0.4 and pinned 4.7.0. `tools/check-native-addon.ts --fast-release` exercises the seven direct-install stages (package, Yarn installation, native build/import/runtime/editor/rendering). The older 73-stage/two-engine and three-layout battery remains opt-in for deeper diagnostics. **None of these tests automatically run as part of a GitHub Release.**

## Measurement and identity

`tools/measure-routine-ci.ts RUN_ID` reports required PR/main CI execution wall separately from queue. The GitHub prerelease tag stays the version authority, staged by `estragon-tag-overlay-v1` without editing the source checkout. The publishing job retains exact tagged-source/main ancestry checks, canonical npm package identity, beta dist-tag and OIDC provenance through the npm publish command. See [package/release instructions](PACKAGING.md).

Historical CI02 timings and pre-publication/post-publication native evidence describe earlier workflow versions, not today's automatic release behavior.
