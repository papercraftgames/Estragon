# UI-05 #203 — native value-control evidence

Review candidate; owner merge pending. Base: owner-merged Radio PR #228, `402e54eb602bf9e7233784fbe1f35e58020d698b`. Final runtime/compiler: **`a430ffb8ba3eba403c19effbb76c5f847423e4dc`**. `f1a01de6a576dfd06f73d551c6580b58e6c07101` changes only contributor tests/docs; all packaged runtime bytes are identical. Delivery adds evidence/documentation only. [Select](../SELECT.md), [numeric controls](../NUMERIC_INPUT.md), [showcase](../../examples/values/Values.gogo), [raw SHA-256 index](../../tests/value/evidence/manifest.json).

## Fresh scope and provenance

Only official **Linux4.0.4** `fc0b241c9` (binary SHA-256 `e9a0db9798cf53385693898af39f98d0065552c0808b9e7eb82cfcb0da880ae9`) and pinned **Linux4.7.0** `5b4e0cb0f` (`f85bbc6b15e22416c7d797cd60b63286dd67b9cb13498847056c18520ae55a75`). Docker/Xvfb/Mesa llvmpipe, software OpenGL and Dummy audio; isolated editor settings and direct Yarn installation. No user checkout addon/preferences were changed.

Full paired regression at `3e0481d` passed with identical development tar SHA-256 **`f7d3a6c1163b91b678d013f069e3828f48f90c425b47401a7a2a1e22b0cc31b9`**. [Both engine results](../../tests/value/evidence/regression/), [exact package members](../../tests/value/evidence/regression/package-manifest.json).

| Full regression stage | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| UI-05 frontend / native graphical game / negative repair | 23 / 79 / 20 PASS | 23 / 79 / 20 PASS |
| Native wheel arbitration / lifetime | 3 PASS | 3 PASS |
| Input frontend / native editor | 22 / 52 PASS | 22 / 52 PASS |
| Radio native / Checkbox native / shared focus | 65 / 27 / 42 PASS | 65 / 27 / 42 PASS |
| Typed keyed data frontend / runtime | 23 / 40 PASS | 23 / 40 PASS |
| Grid/Wrap math / native constraints (including post-gutter percentages) | 95 / 59 PASS | 95 / 59 PASS |
| Native scrollbar geometry/input/pack | 44 PASS | 44 PASS |
| Real editor current/main invalid/repair/Play | 18 PASS, 130.14s | 18 PASS, 72.60s |
| Editor restart / actual native game | 3 PASS, 60.64s | 3 PASS, 44.13s |

Final UI-05 geometry review changed **only three production files** after that full run: `select.gd` enables native long-label clipping; `internal/value_control.gd` hides endpoints whose native minimum cannot fit allocated content; `internal/numeric_control.gd` applies its theme before that minimum check. Binding/compiler, shared scroll/focus/layout and existing controls are byte-identical. Final `--controls-only --editor` acceptance at clean **a430ffb** revalidated every UI-05 native/compiler/editor/package gate on both engines; it does not claim the unrelated full-regression stages reran.

Final control tar SHA-256: **`43a2f59b2120ffb300c3d83eda3262591164d8e594392e1facf795e5ad3c8be6`**. Both engines verify identical installed member bytes, **102 canonical addon UIDs**, exact gallery maps/source content/generated hashes and stable generated UIDs, native pack/reopen and empty manager/focus registries after cleanup.

| Final control stage | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| Frontend / graphical / negative repair | 23 / 79 / 20 PASS | 23 / 79 / 20 PASS |
| Native wheel / geometry | 3 / 8 PASS | 3 / 8 PASS |
| Real editor current/main rejection/repair/Play | 18 PASS, 128.58s | 18 PASS, 80.81s |
| Editor restart / actual game | 3 PASS, 65.77s | 3 PASS, 44.34s |

The final fixture-only commit sharpened the undersized geometry check from zero content to **positive24×14 content** (40×30 host). `--geometry-only` rechecked all8 assertions on both engines with identical runtime **member bytes**; its separate development archive hash is `220b66a08a10dcf7097aad04764c65c74e4f0ca7b69a42931ac0ce95c2daa23d`. Separate packs have distinct archive metadata; [member-byte equivalence](../../tests/value/evidence/geometry/payload-equivalence.json) and each run's own tar provenance are explicit. This mode is not editor/compiler acceptance.

## Commands and rendered proof

```sh
docker exec -e COREPACK_ENABLE_PROJECT_SPEC=0 -e LIBGL_ALWAYS_SOFTWARE=1 -e LP_NUM_THREADS=2 \
  estragon-e04-local xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types \
  /repo/tools/check-values.ts --editor \
  --engine 4.0.4=/evidence/engine404/Godot_v4.0.4-stable_linux.x86_64 \
  --engine 4.7=/evidence/engine47/Godot_v4.7-stable_linux.x86_64 \
  --output /tmp/ui05-final-pair
```

At final runtime source, add `--controls-only` and use `/tmp/ui05-reviewed-controls`. At fixture source f1a01de, replace `--editor` with `--geometry-only`, output `/tmp/ui05-geometry-final`. All three completed pairs exit0 with `UI05_ACCEPTANCE_OK`. Full568.99s / control446.73s / geometry15.07s are opt-in local validation, not routine CI. `bun install --frozen-lockfile`, stable-head `bun run check` (TypeScript +30 policies) and `git diff --check` pass.

Inspected final native captures: [4.0.4 controls](../../tests/value/evidence/final/4.0.4/numeric-gallery.png), [4.7.0 controls](../../tests/value/evidence/final/4.7/numeric-gallery.png), [4.0.4 popup](../../tests/value/evidence/final/4.0.4/select-popup.png), [4.7.0 popup](../../tests/value/evidence/final/4.7/select-popup.png). Both physical Slider axes share the float model; actual thumb pixels are asserted. Native pointer item selection, keyboard popup traversal/Escape, pending IDs, disabled/hidden options, clipping/gutters, canonical numeric editing, native increment buttons, partial text/caret, source replacement/reentrancy, coherent notifications, orientation retention, scene persistence and idle counters are numeric/state assertions, not just passing parses. Popup rendering extends beyond the closed trigger using Godot's own window.

## Baselines and honest failures

`development/` preserves native API/baseline probes: old Binding rejects TYPE_FLOAT; native OptionButton auto-selects its first item; public APIs and native range behavior are verified on both approved versions. Real negative midpoint probes establish native `floor(value/step+0.5)` ties toward positive infinity (unlike GDScript round on negative halves).

Retained failures led to concrete fixes:4.0 partial SpinBox text reset on redundant editable/configuration writes; min200/max300 native scenes loading fields in the wrong order; native parent scrolling stealing editable Slider wheel (0.5 unchanged, offset62→22); long labels growing the trigger (689px native width in204px content). Final probes/acceptance repair each. The initial Down-key Select assertion assumed a different native menu position; Home now explicitly selects the first row. Earlier full000 proof is archived separately, not substituted for final source. The046 controls-only run was superseded/canceled while3e full acceptance replaced it; it is not a paired PASS. One concurrent policy run correctly rejected a changed Git checkout; the stable-head f1a01de rerun passes30/30.

## Limits and next action

Manual interactive Godot4.7 smoke, actual OS IME composition, physical screen-reader integration, mobile virtual keyboard and other operating systems are **UNTESTED**. Native synthetic GUI/editor/window/pixel proof on Linux does not certify those. No multi-select/searchable combo, IntegerSlider, Variant conversion, new overlay/event/binding/layout system, external demo edit, tag/release/publication or automatic merge. PR remains In review until owner merge; independent required CI and owner review are the delivery gate.
