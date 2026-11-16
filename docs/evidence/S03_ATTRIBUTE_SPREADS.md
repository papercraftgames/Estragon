# S03 — ordered native GGX attribute spreading

[#173](https://github.com/papercraftgames/Estragon/issues/173), owner-revised scope,
base `e8bf65c66d8506f84e4c05a261a39a5afae63cdf` (merged L11 #172).
[Contract](../GOGO_LANGUAGE.md#ordered-attribute-spreads-s03),
[ADR-0023](../DECISIONS.md#adr-0023--ordered-native-ggx-attribute-spreading).

S03 adds only general-purpose `{...expression}` in GGX opening attribute lists.
There is no style prop, prescribed style structure, factory, utility, token,
palette/theme Resource, proxy or additional observer. Source expressions and
Dictionary values retain native GDScript semantics, the sole compiler and
complete-description reconciler remain authoritative.

## Outcomes and provenance

Native production tests and both package gates use clean `dd4cab57ea08f41eb09555748e6314ad7d810903`.
The pinned 4.7 editor import repair uses clean `21a03a1`, changing only the collector's
cold-import sequencing. [Source qualification](s03/source-qualification.json)
compares all manifests and authenticates identical addon file bytes, 66 UIDs,
content SHA256 `8ea8c4caa7f2ac6e3ea2d49b0eab90ef46ddffc0338254bec4f34d48fd06cd28`
and tarball SHA256 `ebf6616ff6adf5f198b42902f6bc4495b0333116295bd3d237dcce1f64066dae`.
A final test-only strengthening verifies a still-spread-owned color changed
imperatively to blue stays blue after removal, rather than resetting to the class
default. Both approved engines PASS 28 in focused runs;
[provenance](s03/refined-runtime-provenance.json) records the pending test/docs
work honestly as dirty. These supplemental runs are not package certification;
the clean direct-Yarn production evidence below remains unchanged.
The original pinned 4.7 combined run's editor stage remains FAIL in its raw
results; separately named editor results/logs record the successful repair.
Later documentation/archive commits leave the tested production payload unchanged.

| Check | Official Linux 4.0.4 | Pinned Linux 4.7.0 |
| --- | --- | --- |
| Frontend/native generation/maps | PASS 61 | PASS 61 |
| Semantic publication/rollback/repair | PASS 7 | PASS 7 |
| Complete-description rejection/repair | PASS 93 / 31 intended errors | PASS 93 / 31 intended errors |
| Runtime/layout/paint/input/removal/counters | PASS 28 | PASS 28 |
| Actual editor / restart | PASS 11 / 3 | PASS 11 / 3 |
| Bounded seven-stage package consumer | PASS | PASS  |

Pinned 4.7 focused regressions: GGX runtime 55/editor 89 and native import PASS;
lengths/L11 runtime 243/rejections 24/root-exit PASS; styling runtime 158/rejections 21
PASS. Native Controls 57/native-exit/3 examples and tiny routine smoke PASS. Package gate Counter runtime 24/editor 50 passes
on both approved engines, including actual invalid/unsavable/repair/cache proofs.

Frozen install/static checks 30 PASS; 222 script/UID pairs are present and unique;
both new canonical generated maps authenticate exact source/output. No supplied
Assets, GogoDemo, workflows, versions, releases/tags or publication changed.

## Behavior proved

The lexer/parser produces a distinct ordered spread Attribute with full authored
span. Ordinary whitespace/comments/quoted text/nested braces and inline/function/
variable Dictionaries compile. Spread markers and copied expressions retain
independent authored map spans, including UTF16. Duplicate explicit names reject;
spread collisions and explicit-before/after follow last-wins. Expressions execute
once left-to-right, and each Dictionary is shallow-snapshotted before later argument
effects can mutate its entries. No candidate child Nodes are allocated to expand
attributes. Nested/conditional/keyed descriptions and project Gogo tags work.

Actual destination property/signal metadata splits one final set of values. No
style-name allowlist or arbitrary setter fallback exists. Unknown/read-only/reserved
fields, malformed/non-Dictionary spreads, non-String/StringName/empty keys,
key/bind syntax, bad native types/Object classes, Length/color values, Rect dual
fill, policy/controlled-binding conflicts and invalid/unsafe named Callables all
reject before native commit. Errors preserve the spread source and offending key;
previous IDs/parents/owners, geometry and committed operation counts stay intact.
Every negative computation repairs on a new bindable Dictionary reference.

Native ClassDB setter metadata is used when exposed. Official 4.0.4 lacks it and
its getter-only fields have usage0. A small shared compiler/runtime bridge covers
its six read-only properties across Node/Timer/AnimationPlayer/ShapeCast2D/3D,
verified against the [official class reference sources](s03/readonly-reference.json).
No metadata probe Nodes or new infrastructure are used in production. Native
named-method arity checks use public method metadata on both engines. Custom
bound/unbound/lambda Callables retain native invocation behavior where portable
method metadata is unavailable; an actual bound callback is connected/invoked.

Spread-only omission restores pre-write defaults captured on the actual mounted
Node, including Button _init colors/local 14/8 padding and disabled/text, Rect white
canonical background, Box padding/gap/policies, native visible and script _init
values. No helper/probe Node or user metadata. Independent native changes are
preserved if they differ from the last committed spread value. Explicit surviving
properties remain effective; named-only omission behavior is unchanged. Existing
border-side auto/minimum-zero fallback remains authoritative. A removed name on
an initially unnamed Node uses the native class label because native set_name
rejects empty names after attachment; effective sibling names still preflight.

Bindable reference reassignment recomposes only the observing component. Raw
in-place Dictionary mutation is intentionally unobserved. Retained Node identity,
native GUI/Estragon pointer input, explicit key/conditional and controlled Toggle
remain correct. Color changes repaint without length parsing/layout, layout values
invalidate affected branches, equal-reference writes and idle frames do no work.
Exact S03_COUNTERS records are retained in runtime logs. Unmount releases all
composition records and managed indices.

The real source-authored SpreadGallery renders at 640x480/1000x800. Its panel is
616x327 /976x327, content 580/940, and Button 290x36 /470x36; the min-height floor
clamps authored 20px while width stays 50% of final content. Native/UI clicks 2 each
and controlled edits [true,false] pass; runtime clicks the outer edge. Nested Gogo
children, Rect paint, border pixels and legible foregrounds are inspected.

Inspected captures from real runtime640x480 and repaired editor Play1000x800:
[4.0.4 runtime](s03/spreads/4.0.4/spreads-640.png),
[4.0.4 editor](s03/spreads/4.0.4/editor-spreads-1000.png),
[4.7 runtime](s03/spreads/4.7/spreads-640.png),
[4.7 repaired editor](s03/spreads/4.7/editor-spreads-1000.png).
Only these four selected scene captures are archived, without duplicate variants.

Both actual Play entry points save current Gogo buffers, reject an invalid unsaved
spread with authored diagnostics, retain code/maps/UID/timestamp/cached Script,
then repair and execute the newest rendered game. Restart repeats native source
import and main Play. Editor scene stays free of transient managed output. Native
syntax/undefined-expression failures also retain publication identity and repair;
these are distinct from runtime Dictionary validation. The strict scanner accepts
only exact intentional diagnostics in bounded markers, never arbitrary errors.

## Reproduce

Only official Linux 4.0.4 and pinned Linux 4.7.0 in Docker estragon-e04-local, isolated
settings/PATH, read-only /repo, host /tmp/e04-local mounted /evidence, Xvfb/Openbox,
Mesa llvmpipe/GL Compatibility. Existing authenticated TypeScript downloader restored
only these approved engines after old temporary engine directories were emptied.
Archive/binary SHA checks passed. Normal editing/Play uses Godot only.

~~~sh
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/s03-ready-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-spreads.ts --editor --engine 4.0.4=/evidence/s03-engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/s03-ready'
~~~

[Initial regression command](s03/regression-command.txt),
[tail](s03/regression-tail-command.txt) and
[clean final remainder](s03/regression-last-command.txt) use the same Docker/Xvfb
prefix and only the approved engines. GGX output was moved to container-local
`/tmp/s03-ggx-local` after the documented host-mount permission failure.
The repaired4.7 editor command uses `tools/check-spreads.ts --editor-only
--engine 4.7=/evidence/s03-engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64
--output /evidence/s03-editor-import` with the same prefix; its provenance records
the exact invocation. Host retained tooling uses
`bun install --frozen-lockfile` / `bun run check`; new collector uses TypeScript/Yarn.
No release/tag/registry/OIDC publication or workflow dispatch was performed.

## Failed development attempts and limitations

- Initial engine launch found prior temporary directories empty. Launch failed;
  authenticated downloader restored the same two approved official binaries.
- Test assumptions were corrected: StringName native name differs from String in
  Dictionary equality; use supported local Array.map expression form; Text color
  remains Color; Button background is #514174 and its real default insets14/8.
- A pre-staging static run rejected the not-yet-tracked helper/UID; a later TypeScript
  run caught unchecked array indexing. Stage native-import UIDs and typecheck the
  collector. No policy exemption or source/UID ignore was added.
- Native 4.0.4 rejected newer Callable.get_unbound_arguments_count at parse time.
  Remove the dependency; plain named methods get portable checks, custom native
  Callables retain native invocation behavior. The failure is not relabeled PASS.
- A test used unbind(0), which native Godot rejects. Remove that invalid no-op;
  actual bind(true) callback connection/invocation now passes.
- Installed4.7 editor assertions passed but the strict scanner caught an unnamed
  packed scene-root error. Name the fixture root before packing; no error waiver.
- Final pinned 4.7 cold editor attempt hit duplicate-plugin/documentation-task and
  script-reload/internal errors. It remains FAIL in raw results/excerpts. Finish
  native import before enabling test plugins via established indexProject; the
  separate focused editor run proves the repair without repeating passed runtime.
- GGX host-mounted evidence copying failed chmod with EACCES on an old UID while
  host mode and container mapping differed. Unchanged suite passed with local
  container /tmp output, then evidence was copied out; no source/UID workaround.
- One styling pack correctly rejected source dirty during the test-import fix.
  Resume from clean committed source; no dirty package evidence was accepted.
- Native name probe shows post-attachment empty set_name rejects; document/test
  the legitimate native class-label removal fallback with sibling preflight.

Selected evidence is stored once with [SHA256 index](s03/artifact-index.json), not
bulk duplicated screenshots/tarballs/install trees. Logs are normalized only for
trailing whitespace and renamed .txt; original results retain actual log names.
Original full local runs remain under /tmp/e04-local and /tmp/s03-*.log. Genuine
failure excerpts preserve failures; no fresh untested-platform/minor claims.

Godot 4.0.4 optional isolated preflight/path introspection remains unavailable/BLOCKED;
mandatory transactional actual-path semantic validation and rollback PASS. No
manual interactive smoke ran; automated native editor/game and inspected rendered
captures are the visual/input evidence. Physical keypress tests are not required.
No extra engines/platforms, exhaustive 73-stage suite or speculative style-system
follow-up. Required CI measurement is in the live PR/issue; owner reviews/merges.
