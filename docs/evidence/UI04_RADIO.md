# UI-04 #202 — native RadioGroup evidence

Review candidate; owner merge pending. Base: owner-merged LAYOUT-01 PR #227, `0b581c66d2b99d073125a71331611d9fa775baaf`. Final tested source: **`c839668f550eaa895be0333e4a1092bc54730931`**, clean. Delivery adds documentation/evidence only. [Public contract](../RADIO.md), [gallery](../../examples/radio/Radios.gogo), [raw evidence and SHA-256 manifest](../../tests/radio/evidence/manifest.json).

## Source-qualified proof

Both runs use official Linux4.0.4 `fc0b241c9` (binary SHA-256 `e9a0db9798cf53385693898af39f98d0065552c0808b9e7eb82cfcb0da880ae9`) and pinned Linux4.7.0 `5b4e0cb0f` (`f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75`). Xvfb / Mesa llvmpipe, software OpenGL, Dummy audio; no other engine or platform launched.

Full mode at `8ea348d872f0bafdf3918cbcafe56adc7e61af02` passed on both engines. Its immutable direct-Yarn development tar SHA-256 is `3d83097f0db412b4337a463e5d877054b793007e1d04d52c1ab523b069e3b34e`.

| Full-mode stage | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Radio frontend / graphics / negative repair | 16 / 62 / 18 PASS | 16 / 62 / 18 PASS |
| Input frontend / native editing | 22 / 52 PASS | 22 / 52 PASS |
| Checkbox native Bool binding | 27 PASS | 27 PASS |
| Shared native focus | 42 PASS | 42 PASS |
| Layout math / native allocated constraints | 95 / 59 PASS | 95 / 59 PASS |
| Native scrollbar geometry/input/pack | 44 PASS | 44 PASS |
| Editor current/main invalid/repair/Play | 18 PASS, 104.61s | 18 PASS, 53.65s |
| Editor restart / actual game | 3 PASS, 51.57s | 3 PASS, 31.14s |

Final review reproduced two narrow RadioGroup cases: a selected click-only option suppressed the group's Tab stop, and deferred fallback could steal an explicitly acquired unrelated native focus. The final commit fixes those, validates membership edits before entering SceneTree, and avoids rebuilding the ordered option array during each cached identity lookup. **Only `radio_group.gd` production bytes changed after full proof**; compiler, Button, shared focus/input, reconciler and layout bytes are identical. Focused `--radio-only --editor` revalidated the final immutable package on both engines; it does not claim the full regression stages reran.

Final tar SHA-256: **`43acbfdd7a74a94ebf4011c3a505c7df67a1a3cbe1d3a7594e36439da6d39c17`**. Both engines verified identical installed bytes, all **90 canonical addon UIDs**, deterministic authored maps/content/generated hashes, gallery UIDs, pack/reopen and cleanup.

| Final Radio stage | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Frontend | 16 PASS | 16 PASS |
| Native graphical selection/input/focus/pixels/lifecycle | 65 PASS | 65 PASS |
| Atomic rejection / repair / nested ownership | 19 PASS | 19 PASS |
| Real editor current/main rejection/repair/Play | 18 PASS, 113.57s | 18 PASS, 59.48s |
| Real editor restart / actual game | 3 PASS, 52.48s | 3 PASS, 33.63s |

Final captures inspected: [4.0.4](../../tests/radio/evidence/final/4.0.4/radio-gallery.png), [4.7.0](../../tests/radio/evidence/final/4.7/radio-gallery.png). Both show hollow neutral circles, exactly one selected dot per participating group, row Wrap and vertical choices inside Grid tracks, disabled feedback, scrolling and native controls. Pixel checks independently inspect selected/unselected centers; state alone is not graphics proof.

## Exact commands

```sh
docker exec -e COREPACK_ENABLE_PROJECT_SPEC=0 -e LIBGL_ALWAYS_SOFTWARE=1 -e LP_NUM_THREADS=2 \
  estragon-e04-local xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types \
  /repo/tools/check-radio.ts --editor \
  --engine 4.0.4=/evidence/engine404/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 \
  --output /tmp/ui04-complete-pair
```

At final source, the same command adds `--radio-only` and uses `--output /tmp/ui04-final-radio`. Both exit0 with `UI04_ACCEPTANCE_OK`; elapsed full404.96s / focused348.72s, opt-in local acceptance outside routine CI. `bun install --frozen-lockfile`, `bun run check` (TypeScript +30 policy tests), and `git diff --check` pass. Routine independent CI remains unchanged and must satisfy60s.

## Baselines and retained failures

Clean main Input acceptance on both engines passed at `0b581c6`, tar `abe52852bc3bd36ddb322a56f632311270008d88d2d1ef87431de35a1924abff`. Its actual pointer Toggle reproduction fails single-selection as expected: both values true. Logs are in `baseline/`.

Development logs truthfully retain failed collector setup (copied historical focus relative path; omitted scrollbar probe base), a Checkbox fixture failure reproduced unchanged on main, and before/after focus edge probes. The Checkbox assertion incorrectly forbade the shared model changing after hiding a control: layout exposes a visible Toggle at the old hit location. Corrected assertion verifies hidden Checkbox receives no pressed/focus, preserving legitimate visible-sibling routing. Production Checkbox/Toggle behavior was not changed to conceal it. No failed log counts as acceptance.

## Limits

Manual interactive Godot4.7 smoke, actual OS IME composition and assistive-technology interaction are **UNTESTED**. Native automated GUI dispatch/editor/game/pixels ran on Linux only. No Select/Slider, Variant binding, automatic scroll-into-view, text shaping, global theme, external demo edit, release/publication or automatic merge. PR remains In review until owner merge.
