# B3 acceptance evidence — 2026-11-03

Official engines only: 4.0.4 (`fc0b241c9`, original macOS binary SHA256
`da0fcddf2ab4a28fb8b0d370f287c4c3e166dc2205c49bbd42ecf95dc1595fad`)
and pinned 4.7.0 (`5b4e0cb0f`, SHA256
`445c6f95030e2ca767dd921be1e91bd99e50c3703f91d22a22cd31216c93a80f`).
Contributor orchestration used Yarn 1.22.22 / Node 24.16.0; child engines had empty
PATH and isolated copied/ad-hoc-signed binaries, project and editor settings.

| Check | 4.0.4 | 4.7.0 |
| --- | --- | --- |
| B3 numeric/positive/negative/runtime | PASS, 67 assertions | PASS, 67 assertions |
| B3 real editor save/reopen | PASS, two sessions, both dimensions | PASS, two sessions, both dimensions |
| Native graphics | PASS, six captures inspected | PASS, six captures inspected |
| Metadata UID/path/cached identity + PNG/font | PASS | PASS, including UID path resolution |
| Unexpected sidecars | None | None |
| Second metadata import | Byte-stable after five measured asset normalizations | Byte-stable |
| Full-checkout research script editor diagnostics | **FAIL**, existing R01 Logger APIs unsupported; preserved raw diagnostics | PASS |

All 106 GDScript UID sidecars and five asset import UID values are unique.
The 47 initially untracked script UIDs were preserved; eight new B3 UIDs were
created at canonical paths by the pinned native editor. Existing five real asset
settings remain unchanged in Git. Four texture settings lose six newer default
fields and one font setting loses three fields on 4.0.4 first import; exact text
and hashes are retained in `metadata/4.0.4/rewritten.json` and `results.json`.
No UID is lost or rewritten. This is a documented tracked-file difference when
switching editors, not unexpected untracked noise or an ignored asset suffix.

Exact acceptance invocations (from `/tmp` to avoid the historical Bun package
manager declaration; raw JSON retains command arrays and temporary paths):

```sh
corepack yarn@1.22.22 node --experimental-strip-types /Users/ryan/Projects/Estragon/tools/check-adapter-proof.ts \
  --engine '4.0.4=/Users/ryan/Library/Caches/Estragon/compatibility-engines/4.0.4/godot' \
  --engine '4.7=/Applications/Godot.app/Contents/MacOS/Godot' \
  --output /tmp/estragon-b3-final --graphics
corepack yarn@1.22.22 node --experimental-strip-types /Users/ryan/Projects/Estragon/tools/check-godot-metadata.ts \
  --engine '4.0.4=/Users/ryan/Library/Caches/Estragon/compatibility-engines/4.0.4/godot' \
  --engine '4.7=/Applications/Godot.app/Contents/MacOS/Godot' \
  --output /tmp/estragon-b3-metadata-final
```

B3 provenance reports source head `a92e82a`, dirty=true because metadata checker
work was in progress. Every recorded B3 source hash was compared with the review
source after collection and matched. Metadata provenance reports `0feb239`, clean.
These are development proof snapshots, not matching clean release certification.
The B3 runner saves real-editor persisted scenes as `.tscn.txt` evidence, not
runtime resources. Logs are unmodified, including 4.0 warnings and research errors.
No physical keypress test was scheduled; editor automation and native captures
provide the required evidence. No other engine versions were used.

Existing regression commands also passed:

```sh
bun install --frozen-lockfile
bun run check
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot bun run check:godot
```

Reference suite: 202 tests / 671 expectations, typecheck, stage-0 IR and generated
GDScript/map consistency. Godot regression: import, every-script parsing,
legacy/runtime/native fixtures and fail-closed negative probes. Raw logs are
`existing-reference.log` and `existing-godot-regression.log`. CI additionally
runs the retained B1/B2 and existing editor/C01 checks on their established
Linux 4.7.0 and macOS 4.0.4 jobs; see #75/PR for live run links.

All 12 graphics captures were visually inspected: retained teal/purple native
visuals, bounds-driven spacing after geometry changes, and larger native views.
No screenshot was generated with a dummy/headless renderer. 3D camera coordinates
remain native (resizing changes framing). C01 strict release remains **BLOCKED**;
B3 acceptance does not waive its existing failures or start C1.
