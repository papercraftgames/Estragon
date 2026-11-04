# C1 acceptance — 2026-11-04 UTC

Working native runtime foundation, issue #77. Source contract:
[docs/NODE_RUNTIME.md](../../../docs/NODE_RUNTIME.md). Runnable scenes:
`res://examples/node_runtime/TwoD.tscn` and `ThreeD.tscn`.

| Verification | Official 4.0.4 | Pinned 4.7.0 |
| --- | --- | --- |
| C1 runtime / positive / negative / scope / native lifetime | PASS, 147 assertions | PASS, 147 assertions |
| Native pack/reload and explicit owners | PASS, including live restored membership and unowned exclusion | PASS |
| Real editor save/reopen | PASS, two sessions, both dimensions each | PASS, two sessions, both dimensions each |
| Native graphics | PASS, six captures inspected | PASS, six captures inspected |
| Metadata identity, actual image/font imports, no unexpected sidecars | PASS with documented old-editor differences | PASS |

C1 acceptance ran from **clean committed source `95a5e78`** after the persistence
fix. All per-file runtime/demo/test/tool hashes in provenance were rechecked
against delivered source. Original binary identities are 4.0.4 official
`fc0b241c9`, SHA256
`da0fcddf2ab4a28fb8b0d370f287c4c3e166dc2205c49bbd42ecf95dc1595fad`,
and 4.7.0 official `5b4e0cb0f`, SHA256
`445c6f95030e2ca767dd921be1e91bd99e50c3703f91d22a22cd31216c93a80f`.
Runner copies are verified before macOS ad-hoc signing and isolated settings;
child PATH contains no compiler/Node/Bun executable. Orchestration used Yarn
1.22.22 and Node 24.16.0; end-user demos require only Godot.

Exact local acceptance (from `/tmp`, outside the historical Bun package-manager
manifest; raw provenance retains argv, temporary paths, engine/source hashes):

```sh
corepack yarn@1.22.22 node --experimental-strip-types /Users/ryan/Projects/Estragon/tools/check-node-runtime.ts \
  --engine '4.0.4=/Users/ryan/Library/Caches/Estragon/compatibility-engines/4.0.4/godot' \
  --engine '4.7=/Applications/Godot.app/Contents/MacOS/Godot' \
  --output /tmp/estragon-c1-acceptance --graphics
corepack yarn@1.22.22 node --experimental-strip-types /Users/ryan/Projects/Estragon/tools/check-godot-metadata.ts \
  --engine '4.0.4=/Users/ryan/Library/Caches/Estragon/compatibility-engines/4.0.4/godot' \
  --engine '4.7=/Applications/Godot.app/Contents/MacOS/Godot' \
  --output /tmp/estragon-c1-metadata-final
```

Metadata snapshot is clean source `9dc47ab`, before the coordinator persistence
fix (which changes no UID/import settings). It checks all 119 script sidecars and
five real asset settings (124 unique IDs), including the six new public runtime
script identities. New UIDs came from the pinned native editor at canonical
source paths, not temporary drivers. Old proof UIDs and five asset settings are
unchanged in Git. Final-head CI repeats metadata with current source.

The existing full-checkout 4.0 R01 Logger research diagnostics remain actual
**FAIL** in metadata editor stages; the named exact diagnostic set is retained,
not hidden. First import removes only the known newer default fields from five
asset settings, retaining UIDs; second import is stable, with no unexpected
sidecars. See adjacent metadata results/raw logs/before-after text and the B3
metadata contract. This does not certify all repository research on 4.0.

## Persistence failure found and corrected

Initial C1 editor acceptance on 4.0.4 **FAILED**, even though runtime numerical
checks passed. The diagnostic log is preserved under `development/`. Root and
reentry were active but the restored participant had no root or layout work.
PackedScene restored an empty serialized WeakRef from Node metadata after script
construction. The production runtime now resolves the live participant field,
so no coordinator object is serialized into C1 metadata; the proof-only registry
refreshes at tree entry for compatibility. Runtime reload and both real editor
sessions now assert restored membership/allocation/owners, and saved C1 scenes
assert no `Object(WeakRef...)` scope data. Failed evidence was not relabeled PASS.

## Regression and graphics scope

`bun install --frozen-lockfile`, `bun run check` (202 tests / 671 expectations,
typecheck and generated IR/GDScript/maps), and pinned
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bun run check:godot`
passed at the implementation checkpoint; raw logs are adjacent. Focused promoted
B2 math (18 assertions) and B3 old-path runtime (67 assertions) also passed on
4.7. CI retains full B1/B2/B3, Counter/compiler/native editor/Play and C01 development
integrity checks on only Linux 4.7.0 and macOS 4.0.4. See #77/PR for final-head links.
No nine-version sweep or other engine version was launched.

All 12 native captures were inspected: teal growth moves the purple sibling;
the orange native decoration remains under its independent explicit entry;
resized 3D camera framing is native Godot behavior. No dummy renderer generated
these images. Headless numeric/parse checks are separate. No physical/manual
keyboard acceptance test was required or scheduled; automated methods drive the
same scene interaction. No manual legacy Hello/Counter visual smoke was run.

Strict C01 release remains **BLOCKED**, old evidence/fingerprints unchanged.
This is not publishing/platform certification, C2 compiler cutover, C3 widget
parity or legacy retirement. Owner review/merge is the next step; no C2 started.
