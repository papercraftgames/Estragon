# CI01 / CI02 — small routine checks and bounded release certification

[CI01 #109](https://github.com/papercraftgames/Estragon/issues/109) keeps PR/main checks within a **60-second execution-wall budget**. [CI02 #113](https://github.com/papercraftgames/Estragon/issues/113) reduces **automatic release** testing; it does not change product behavior or permit publishing without real evidence.

## Routine PR/main

`ci.yml` runs frozen TypeScript/static/policy checks and, for code changes, at most one tiny Godot 4.7 headless native smoke. No full suites, editor, graphics, Docker or apt. Documentation-only changes skip native execution. Required check names remain visible (including the policy-only 4.0.4 job) to avoid invalidating branch protection. `tools/measure-routine-ci.ts RUN_ID` reports actual run wall separately from queue time; never claim an unmeasured result.

## Mandatory lean release gate

For owner-published reviewed prereleases, `certify.yml` checks the **exact clean source SHA** on both approved Linux engines: official **4.0.4** and pinned **4.7.0**. Each runs `tools/check-native-addon.ts --fast-release`, which first stages the event-bound tag overlay in both Godot/npm metadata, packages those exact versioned bytes and executes **one fresh, direct Yarn node_modules consumer** (not three placements). All seven stages are required: pack, install, native build, Godot import, real runtime/bindables, cold editor Play/rejection/recovery, and rendered visual assertions. File/UID hashes and native parse/load errors remain checked. Tests use Xvfb + software OpenGL; the GL-compatibility consumer does not need a Vulkan package install or `vulkaninfo`.

The `fast-release` evidence profile explicitly **cannot masquerade as the full profile**. `assert-release.ts` rejects missing/failed stages, wrong/non-direct layouts, invalid engine/source/provenance, missing logs, log hash mismatch or a mismatched summary. `verify-npm-release.ts` requires that fast profile from **both current-run jobs**, validates their matching, reproducible tarballs against the exact reviewed source and complete allowlist, and then approves only the tested artifact. No old main/PR CI or previous certification can authorize publication.

The GitHub release still triggers npm **OIDC** publication, beta tag/provenance/integrity checks, and two independent fresh public-registry Yarn consumers. Those post-publish consumers now test direct node_modules installation only (one each), including real editor and rendered checks; registry tarball integrity remains identical to the pre-publication artifact. A failed consumer still fails the release result; registry bytes remain immutable.

## Optional deeper regression, not required every release

The original **73-stage × 2-engine** acceptance and its **direct/relocated/standard** installation matrix are retained for targeted diagnostics or explicit manual use. They are **not** automatically invoked by release, PR or main CI. For a bounded local check, use `--suites=compiler` or another focused group on one approved engine. For a release-equivalent local run, use `--fast-release`. For the historical exhaustive suite, omit both flags. New/changed risky behavior should receive relevant focused proof; avoid routine full runs and Docker.

## Measurement and tradeoff

The completed release run [42316297151](https://github.com/papercraftgames/Estragon/actions/runs/42316297151) took about **923 seconds wall**. The 4.7 job alone spent **348 seconds** preparing/probing Vulkan and **347 seconds** in the full native suite. CI02 removes those automatic expenses. **2–4 minutes is a target, not a measured guarantee**: validate actual release wall time, billed runner-minutes and smoke failures at the next owner-triggered release. The reduced default is intentionally *less exhaustive*; use opt-in suites when changes to layout, imports, export, or the editor warrant them.

## P04 tag overlay and candidate evidence

[#119](https://github.com/papercraftgames/Estragon/issues/119) keeps Git plugin metadata on a development marker. Release certification independently derives a version from the actual published-prerelease event; dispatch previews require an explicit proposed `candidate_tag` and remain `mode=preview`, never publication authorization. Both engine jobs emit source/tag/mode/recipe/version, per-file hashes and identical reproducible tar identity. Native consumers require installed plugin/npm version agreement. Preparation reconstructs only the authorized plugin.cfg/npm substitutions over reviewed source; all unexpected differences reject. See [packaging](PACKAGING.md).

No additional routine job, engine, Docker/Vulkan installation or exhaustive suite is introduced. The existing readonly candidate certification mode can verify a task branch before merge; its artifact and result do not constitute an actual release or registry proof.
