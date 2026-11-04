# ADR-0015-C3 acceptance

Only **official Godot 4.0.4** (`fc0b241c9`) and **pinned 4.7.0** (`5b4e0cb0f`), both Linux. Runtime/editor sources are task head `cda59dfa1a452058c0cfc74350f933b39e059611`; PR runners record the actual synthetic merge SHA and full source hashes. Later evidence/status documentation does not change those tested runtime sources.

| Acceptance | 4.0.4 Linux | 4.7.0 Linux |
| --- | --- | --- |
| Native Godot-only build/import | PASS | PASS |
| Runtime geometry, actual primary input, Counter increment/reset, nested resize, retained identity/subscriptions, cache/batch/idle behavior, native scene persistence | PASS — 32 assertions | PASS — 32 assertions |
| Actual normal editor save/unsaved main/current Play, mapped syntax/semantic failures, unsavable-source block, rollback/cache identity and repair | PASS — 41 assertions | PASS — 41 assertions |
| Actual Mesa/OpenGL native graphics | PASS — three captures | PASS — three captures |

CI: [4.0.4 acceptance](https://github.com/resistdesign/Estragon/actions/runs/41869714683), [4.7 acceptance](https://github.com/resistdesign/Estragon/actions/runs/41869714967). Exact runner commands and executable/source hashes are in each `provenance.json`; each stage's command, exit status, diagnostics and timing are in `results.json`. Full CI artifacts retain existing B1/B2/B3/C1/C2, metadata and C01 evidence. This directory preserves only C3 logs/results/provenance/captures; no copied addon/generated executable scripts or duplicate UID identities.

Commands (CI wraps the runner in `xvfb-run -a` with verified software Mesa/Vulkan, and runs Yarn from the runner temp directory):

```sh
corepack yarn@1.22.22 node --experimental-strip-types tools/check-native-ui.ts \
  --engine 4.0.4=/absolute/verified/official/linux/godot \
  --output /new/absolute/c3-output --graphics
corepack yarn@1.22.22 node --experimental-strip-types tools/check-native-ui.ts \
  --engine 4.7=/absolute/verified/pinned/linux/godot \
  --output /another/new/absolute/c3-output --graphics
```

Native processes use an empty external-tool PATH. Editor games are headless with Dummy audio, while runtime and capture stages use the real native renderer. Unexpected native errors, failed assertions, missing markers/timeouts and resource leaks fail. Editor negatives are narrowly matched at the authored/generated fixture path. Earlier focused failures and their fixes are recorded on #81; they are not relabeled PASS.

Captures are `c3-zero.png`, `c3-one.png`, `c3-reset-resized.png`: native visible count changes, disabled Reset, two nested stack axes and real viewport resize. Images from both engines were visually inspected. No interactive/manual Godot 4.7 smoke session ran; no physical-key test is required. No other engine/platform is freshly tested or certified. **C01 strict release remains BLOCKED**, independently of green development CI; archived old failures/accepted exceptions retain their actual statuses.

`.gdignore` excludes only this evidence directory from project imports, avoiding image `.import` churn or fixture script registration. See [API/demo/C4 inventory](../../../docs/NODE_UI.md). C4 is queued, not implemented; PR #82 awaits owner review and must not auto-merge.
