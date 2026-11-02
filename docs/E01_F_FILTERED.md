# E01-F filtered never-associated tab investigation

Work ID E01-F, [issue #44](https://github.com/resistdesign/Estragon/issues/44).
This is an evidence branch, **not a resolved implementation or release acceptance**.
Production addon files are unchanged from main `17a7d9b`. The exact hidden-tab
requirement remains in force pending explicit owner disposition.

## Reproduce

```sh
GODOT_BIN=/absolute/official/godot ESTRAGON_KEEP_COMPAT_TEST=1 \
  sh tools/check-highlighting-compat.sh
python3 tools/check-filtered-highlighting.py \
  --engine 4.7=/absolute/official/godot --output /tmp/e01-f-strict
```

The historical harness intentionally collects an expected negative. Its zero
exit does not certify filtered association. The new focused probe defaults to
nonzero if hidden association fails. `--collect-only` permits collection while
retaining each explicit FAIL; it is not certification. Engine selection is
repeatable; use all nine entries in `tests/compatibility/engines.json`.

Both harnesses copy official binaries into self-contained temporary directories,
ad-hoc sign only the copies on macOS and use an empty executable PATH. The new
probe additionally verifies native version and input binary SHA-256 against the
manifest. It changes only its own isolated settings/project. Python orchestrates
contributor tests; the addon acquires no external dependency.

The focused driver opens byte-identical Counter.gogo, Background.gogo and
Counter.gogo.txt without registering Estragon. Before filtering, the fixture
locates each actual CodeEdit by exact native list path and tab metadata. These
references are test ground truth, never supplied to the association. It checks
both Gogo tabs are Plain Text and Background has no prior Estragon path metadata,
then filters them out before enabling the unmodified association. It records
bound getter availability, editor path/resource properties and metadata,
highlighter resource and uncached association identity. It checks that source,
edit version, unrelated highlighter, filter and preferences remain unchanged.
It then reveals/activates tabs, checks declaration/markup colors, independent
instances, previously associated filtered behavior and disable/re-enable.

A second editor process restores tabs after the existing seed fixture explicitly
sets their persisted highlighter to Plain Text. The probe filters those restored
tabs **before** enabling Estragon and repeats all checks. Ordinary unfiltered
startup restoration remains covered separately by the historical harness.

## Current-main measurements

The original harness reproduces `E01_FILTERED_UNASSOCIATED_UNMET` on all nine
official engines; its normal/restart checks and separate full-addon startup
succeed on current production code. Historical pre-C01-F startup failures are
not the current result.

The final focused matrix executes clean `abc1d8d` (production unchanged from
`17a7d9b`). [Full records and log hashes](../tests/compatibility/e01-f/results.json)
and per-engine `baseline.log`, `phase_1.log`, `seed.log`, `phase_2.log` retain the
actual observations. Each editor phase passes 30 invariant/color/recovery
assertions: **18 phases, 540 assertions**. These do not include successful
acceptance of the hidden identity requirement.

| Official engine | Fresh hidden Plain Text | Restored hidden Plain Text | Reveal + activate / known filtered / lifecycle |
| --- | --- | --- | --- |
| 4.0.4 | FAIL | FAIL | PASS |
| 4.1.4 | FAIL | FAIL | PASS |
| 4.2.2 | FAIL | FAIL | PASS |
| 4.3 | FAIL | FAIL | PASS |
| 4.4.1 | FAIL | FAIL | PASS |
| 4.5.2 | FAIL | FAIL | PASS |
| 4.6.3 | FAIL | FAIL | PASS |
| 4.7.0 pin | FAIL | PASS | PASS |
| 4.7.2 | FAIL | PASS | PASS |

The two 4.7 restart passes have an exact explanation in the **before-enable**
identity records: the restored Plain Text highlighter already owns the native
TextFile with the correct resource path. The existing adapter uses that resource
without consulting the filtered list. Fresh default Plain Text instances return
null on the same engines. Looking only after association would lose that evidence,
because the replacement highlighter has no native bound resource. The probe
therefore records both moments. There is no earlier Estragon metadata in either
starting state. Revealing alone, before activation, remains plain on all failing
cases; activation supplies identity and correct colors.

A separate strict pinned-4.7 command (without `--collect-only`) exits **1**, even
though the restart case passes and both invariant phases pass. Its
[separate evidence](../tests/compatibility/e01-f/strict/results.json) proves the
collector does not hide the fresh-tab failure behind a successful process/phase.
No CI run or positive filtered-tab acceptance is claimed.

## Identity limits and attempted approaches

The [4.0 ScriptEditor public API](https://docs.godotengine.org/en/4.0/classes/class_scripteditor.html)
returns ScriptEditorBase objects, but `get_open_scripts()` and the change/close
signals expose Script resources, not TextFiles. Registering a highlighter does
not apply it to existing tabs. Native `get_edited_resource()` exists in C++ but
is not bound to scripts on ScriptEditorBase. Its property list likewise supplies
no edited TextFile resource. The bound underscore getter on the active Plain
Text highlighter can return null. An extension-registration callback supplies no
resource argument with which to recover this identity.

The existing ItemList adapter works only when the actual tab has an exact native
path/index entry. Filtering removes that entry. Cached `estragon_gogo_path` can
preserve a previously identified tab, but is absent in the target case and cannot
prove current identity for a never-associated tab. The probe never injects it.

One concrete candidate emerged from native source: `_edit_res_path` metadata on
ScriptEditorBase in 4.0–4.3. It is assigned from the edited resource before native
list filtering (and updated on native list refresh). However it is absent in
4.4–4.7.2; it cannot meet the all-minor requirement. No partial production adapter
was installed. A remembered path also needs resource freshness checks before
being used for writes; this investigation does not relax C01-G's save boundary.

Source anchors (official tags / corresponding engine hashes in the manifest):

- [4.0.4 ScriptEditor implementation](https://github.com/godotengine/godot/blob/fc0b241c9/editor/plugins/script_editor_plugin.cpp):
  `_bind_methods`, `get_open_scripts`, `_update_script_names`, `_edit_res_path`.
- [4.3 ScriptEditor implementation](https://github.com/godotengine/godot/blob/77dcf97d8/editor/plugins/script_editor_plugin.cpp):
  last tested minor containing `_edit_res_path`.
- [4.4.1 ScriptEditor implementation](https://github.com/godotengine/godot/blob/49a5bc7b6/editor/plugins/script_editor_plugin.cpp):
  metadata candidate absent.
- [4.7 ScriptEditor](https://github.com/godotengine/godot/blob/5b4e0cb0f/editor/script/script_editor_plugin.cpp)
  and [TextEditorBase](https://github.com/godotengine/godot/blob/5b4e0cb0f/editor/script/script_editor_base.cpp):
  C++ edited-resource ownership, filtered list construction, highlighter binding
  and Plain Text initialization. Native source was also inspected at every
  intervening tested minor and latest 4.7.2.

Reading editor cache order, filenames, identical buffer contents, tab position
alone or a cached ResourceLoader entry does not establish which resource a tab
owns. Temporarily switching native menu highlighters, changing the filter,
activating every hidden tab or rewriting persisted cache would alter unrelated
editor state and require invasive internal UI behavior. These approaches were
rejected before production implementation. No fake resources, per-frame polling,
private memory access, engine fork or new native dependency was introduced.

## Owner disposition required

The safe current behavior is to leave an unknown hidden tab unmodified, then
associate it when its native identity is exposed and the tab is activated.
Already associated tabs retain colors while filtered. This is an available
alternative, **not satisfaction of the exact issue acceptance**.

The owner must choose whether to accept that limitation explicitly and defer
invisible never-associated recoloring, allowing C01-H to proceed with the precise
exception documented; or retain #44 as a blocking requirement pending a reliable
native edited-TextFile identity API/bridge. No acceptance change, queue advance,
PR or merge is authorized by this negative finding alone.

No production fix means no new positive hidden-tab acceptance or release claim.
Full C01-F/G Play/lifecycle, native generation, runtime, graphical/manual smoke,
Bun reference suites and CI were not rerun for this test-only investigation.
The historical harness separately reruns normal E01 and full-addon startup on
current production code; it is not a substitute for those broader suites.
