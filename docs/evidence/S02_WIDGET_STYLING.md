# S02 — one native widget style and foreground path

[#169](https://github.com/papercraftgames/Estragon/issues/169), base `e62fcf9`
(merged S01 #168). [Contract](../STYLING.md#s02--text-rect-button-and-toggle),
[ADR-0021](../DECISIONS.md#adr-0021--shared-widget-foregrounds-and-explicit-local-state-colors).

## Delivered behavior

Text/Rect/Button/Toggle now share Component2D's native draw signal and the same
color helper, Length parser and pure layout core as Box/Entry. Padding is declared
once, with true local Button14/8 defaults represented by uniform auto; explicit
padding10/0 replaces the default without fake side overrides. Text measures only
glyph metrics and draws at the content origin; Button centers foreground within
content but hit-tests its full transformed border-box. Rect canonical background
and legacy fill stay synchronized with canonical-only storage and source-located
GGX dual-assignment conflicts. State colors retain their original palette and
priority; one native background/border pass precedes glyph/checked foreground.
Native font signals, pressed/value_changed and controlled bool binding remain.
No cascade, helper Nodes, polling, second reconciler or S03/S04/3D styling.

## Source-qualified verification

Final product/test source: `274a2b6e370fcacfca431c09d4d30ecf6b24f3b2`. Earlier runtime/core/Box/lengths/Controls/GGX regressions are clean `9ded59c`/`b08d460`; later changes are the byte-stable native icon and the narrow lazy project-scope initialization described below. All records retain their actual source. Final package and styling checks use the same clean final source.

| Official Linux engine | Runtime | Native rejections | Actual editor / restart | Direct Yarn |
| --- | --- | --- | --- | --- |
|4.0.4|158 PASS|21 exact PASS|39 /33 PASS|65 UIDs/bytes unchanged|
|pinned4.7.0|158 PASS|21 exact PASS|39 /33 PASS|65 UIDs/bytes unchanged|

Both complete seven-stage package gates and independent strict assessors PASS, runtime24/editor50 per engine. Identical development tar `073230bf48a812547a60b506b80c6765ef99120f808c393976ef9785b38ce40c`, source content `35c5f84f7b1ad9d52c0d7b75b084cc89561e3775bca1aae350b15885ce2d0025`. See each engine’s results/provenance/manifest under [selected evidence](s02/artifact-index.json).

Existing focused regressions: pinned4.7 core18/runtime149, Box68, native Controls57/Exit/examples3, GGX55/editor89 and native UI32 with exact two native rejections PASS. Both engines lengths195/actual root Exit PASS. Final-source two-way50 runtime/compiler/editor42/visual PASS and routine smoke PASS. The native UI diagnostic-bracket-only harness update is acf04ef; product/package bytes remain those tested at274a2b6.

Frozen install/static30,207 unique script/UID pairs and4 authenticated styling maps PASS. Required PR CI and its execution budget are linked in the live GitHub handoff.

The direct Yarn consumers use the actual installed node_modules package, with
isolated settings/PATH, no copying/symlink/.gdignore workaround and unchanged
installed addon bytes/65 canonical script UIDs. Exact package manifests record
source/content/tar/engine hashes. Local development packages/gate regression do
not authorize publishing or constitute tag-specific release certification.

Both runtime engines prove the retained S01 300→264 atX12 sample, percent/root/
margin/gap/grow/Spacer geometry, all widget padding defaults and explicit0/units,
asymmetric content/label origin and native font metric-resource changes. Actual
pixel checks cover normal/hover/held/disabled/checked colors, borders and every
matching Text/label foreground pixel inside content. A translucent Rect is
compared with one independent native draw_rect, proving one paint pass without
assuming a renderer color-space formula. Checked indicator retains #65f4b0.

The default Button palette is sampled from actual native rendering in all five original pointer cases. A positive0.5×0.25 widget safely paints clamped borders with zero inner content.

The transformed outer-edge Button click activates once; disabled blocks it.
Native Control input remains functional. Controlled Toggle produces exactly one
edit, while programmatic bool projection produces no reciprocal edit. Resize,
key reorder and conditional insertion/removal retain all widget IDs/parents/
owners and surviving subscriptions. Re-entry connects one draw hook; pack/reload
preserves canonical Rect String/Color and Button default/explicit side distinctions.
Zero-size widget color updates emit no rectangles; negative geometry is clamped.
Invalid native setters preserve good paint/specs; literal/dynamic color/length/
dual-fill failures retain generated code/maps/cached Script/tree and repair.

State counters on both engines: panel measure/arrange2/2, Button1/1, length parses27
and composition runs3 remain identical across four state-color writes and a held
state change. Button draw3→4 and commands→20; equal writes and idle frames change
nothing. Padding changes remeasure the existing branch. Existing S01 color-only
counters/layout results remain asserted by the same fixture.

Actual editor main/current games retain the old container proof and run the
new WidgetGallery at640×480/1000×800 with native/UI clicks2 each, controlled edits
[false,true] and final enabled=true. The asymmetric Button content is[P(18,7),
S(88,35)], label origin(18,10.5). Every actual Text/Rect/Button/Toggle Inspector
exposes shared/local fields, edits hex values and performs undo/redo; Button
padding undo restores true auto14/8 defaults. All state color fields are edited.

Representative actual captures were visually inspected: [4.0 widgets640](s02/styling/4.0.4/widgets-640.png), [4.7 widgets1000](s02/styling/4.7/widgets-1000.png), [actual editor widget game](s02/styling/4.7/editor-widgets-640.png), [Text Inspector](s02/styling/4.7/inspector-text.gd.png), [Rect Inspector](s02/styling/4.7/inspector-rect.gd.png), [Button Inspector](s02/styling/4.7/inspector-button.gd.png), [Toggle Inspector](s02/styling/4.7/inspector-toggle.gd.png).

## Reproduction

Only official Linux4.0.4 and pinned Linux4.7.0, in container estragon-e04-local;
repository mounted read-only `/repo`, host `/tmp/e04-local` mounted `/evidence`.
Each invocation uses isolated XDG/editor settings and software GL Compatibility
under Xvfb/Openbox. Exact engine executable identities are in provenance. Godot4.0.4 reports isolated preflight/path introspection unavailable; mandatory actual-path semantic validation and transactional rollback still pass. No isolated preflight PASS is claimed there.

~~~sh
docker exec -w /tmp -e XDG_RUNTIME_DIR=/tmp/e04-runtime estragon-e04-local \
  xvfb-run -a sh -c 'openbox >/tmp/s02-ready-openbox.log 2>&1 & exec corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-styling.ts --editor --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/s02-ready'
~~~

[Exact regression command script](s02/regression-command.txt), [native-filesystem resume](s02/regression-resume-command.txt) and [final package/remaining regression command](s02/final-package-and-regression-command.txt) use the same
Docker/Xvfb/Openbox prefix for the bounded seven-stage check-native-addon
--fast-release on both engines and proportional existing native/Box/lengths/
Controls/GGX/two-way/UI/routine checks. Host frozen install and `bun run check`
remain the retained tooling checks; new tooling uses TypeScript/Yarn. No normal
editing/Play external compiler process is introduced.

## Genuine failed attempts, native Inspector and limits

- The first new test module used `Button` as an alias, conflicting with the
  native GDScript class; it now uses explicit UiButton. Original compile error
  is retained. A font test initially expected a new core measure after an
  unchanged font emitted changed; the correct proof changes FontVariation glyph
  spacing and verifies real size/reflow/subscription, not a forced cache miss.
- S01's earlier inherited-global-class Inspector icon failure remains truthful
  historical evidence. S02 uses supported @icon inheritance with a small byte-stable native
  PlaceholderTexture2D .tres in the runtime subtree. Both engines exercise actual
  widget Inspector categories without cache mutation or diagnostic exemptions.
  No SVG/import/package-type rule change was necessary.
- Initial rapid multi-object Inspector undo checks merged same-named native
  MERGE_ENDS actions across disposable test objects. Live diagnostic snapshots
  showed undo did not target the current object; each independent fixture now
  begins with isolated scene undo history and waits for the actual Inspector
  object. Production undo code was not altered. A later4.0 diagnostic accessed a
  property-control reference freed by a native Inspector rebuild; removed that
  stale diagnostic, while assertions continue to read the live widget.

- The first shared GradientTexture2D icon passed real Inspector checks but pinned4.7 normalized its subresource header during native save, failing installed-byte integrity. A dependency-free native PlaceholderTexture2D icon saves identically on both approved engines; both real editor and package gates were rerun without weakening the integrity audit. The original failure and native save comparison are retained.

- GGX and two-way each built successfully but failed copying a generated UID with EACCES/chmod on Docker Desktop’s shared evidence mount. The unchanged runners are retried once with native container /tmp output, then copied to evidence. Original failures are retained; this is an output-filesystem limitation, not a bypass/product fix.

- The unchanged existing two-way regression reached all live lifecycle assertions, then its optional-context Compiler.compile cases exposed a pre-existing Nil project read in resolver._gogo (identical to main). Initialize the existing lazy scope before reading its index: one executable line, no resolver architecture change or validation bypass. All50 original runtime/compiler assertions now pass, including the negative contracts; full editor/graphics and final package/styling gates also use the corrected source. The original failure is retained.

- The older native UI fixture intentionally wrote invalid width/gap values but its runner aborted on the shared Length errors before checking retained state. Kept both writes and the assertion, added a deferred output bracket and exact accounting for those two known messages; all other/extra/unbracketed errors still fail. Native UI32 and the exact two rejections now PASS. No product behavior or validation safeguard was weakened.

Concise selected final provenance/results/logs/captures and failure excerpts are
committed once, authenticated by [archive SHA256 index](s02/artifact-index.json).
Full original runs remain under `/tmp/e04-local`, and GitHub checkpoints/handoff
name exact source and original paths; duplicate development consumers/artifacts
are not bulk-committed. Archived .log text is renamed .txt with trailing whitespace
normalized; original result log names/manifests are retained as provenance.
No manual interactive Godot smoke, physical keypress, macOS/extra platforms,
additional engine versions, full73 suite, GogoDemo/Assets edits, CI workflow,
versions/tags/release/npm publication or merge. S03/S04/focus/shaping/3D/Grid remain
out of scope. Owner review and merge are still required.

Final package command under the Docker/Xvfb/Openbox prefix: `corepack yarn@1.22.22 node --experimental-strip-types /repo/tools/check-native-addon.ts --fast-release --engine 4.0.4=/engines/godot-verified-4.0.4/Godot_v4.0.4-stable_linux.x86_64 --engine 4.7=/engines/godot-verified-4.7/Godot_v4.7-stable_linux.x86_64 --output /evidence/s02-package-ready`. [Final two-way/UI command](s02/final-two-way-ui-command.txt), [native UI/routine harness follow-up](s02/native-ui-routine-command.txt).
