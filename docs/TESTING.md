# Current native-addon verification

Only official **4.0.4** and pinned **4.7.0**, on Linux in CI. No other-version/platform sweep, Python, physical keypress gate or standalone-application export requirement. Run focused checks while developing, then one relevant two-engine acceptance. Historical nine-engine/macOS/C01/B1–C3 reports remain truthful archives, not rerun instructions or perpetual blockers.

Normal addon authoring needs only Godot. Contributor runners are TypeScript; new orchestration uses Yarn/Node. Existing Bun manifest/typechecking remains optional developer tooling (no compiler implementation or end-user dependency).

~~~sh
bun install --frozen-lockfile
bun run check
~~~

Current CI runs these policy/typechecking tests once and the native addon runner once per approved Linux engine. No duplicate compatibility workflow remains. Select manual verification_mode=focused for compiler/UI/distribution development on 4.7 only; it cannot satisfy release acceptance.

~~~sh
# From a contributor environment; output directory must be new and absolute.
xvfb-run -a corepack yarn@1.22.22 node --experimental-strip-types tools/check-native-addon.ts \
  --engine 4.0.4=/absolute/verified/linux/godot \
  --engine 4.7=/absolute/verified/linux/godot --output /tmp/new-addon-acceptance
~~~

Use the workflow's LIBGL_ALWAYS_SOFTWARE=1, verified lavapipe VK_DRIVER_FILES/VK_ICD_FILENAMES and isolated XDG_RUNTIME_DIR. Xvfb supplies X11, not Vulkan; the workflow verifies the software ICD rather than hiding Vulkan initialization errors. tests/compatibility/linux-engines.json pins official archive/executable hashes and versions; the downloader additionally authenticates 4.0.4 against its official SHA-512 manifest. Engine copies and editor settings are isolated and native child PATH has no external tools.

Required coverage:

- Native compiler lexical composition, deterministic code/maps, ordinary lambda factories, code-only models, Node-only/type/child/signal negative diagnostics and actual-path publication/dependency/cache/rollback/fresh failure.
- Shared mathematical layout plus native 2D/3D bounds, identity, reparent/free, subscriptions, branch invalidation, batching, native owner packing and real-editor reopen.
- Gogo-authored 2D/3D runtime/signals/type failures and normal editor source-map/save/unsaved main/current Play failure/repair.
- Native Counter geometry/input/resize/cache/identity, native highlighter and real editor Play; real graphics captures for UI and dimensional demos, visually inspected separately from headless assertions.
- Canonical UID pairing/uniqueness and clean import stability, including measured first-import asset defaults on 4.0.4. Research/evidence-only roots are Godot-ignored; there is no known-Logger-error exception in current product import.
- Cache-free fresh addon installation and native scene execution without contributor tooling; remove generated outputs and .godot, rebuild via bundled native API and execute current source; create/load a native resource pack in a separate bare process. Native addon code is the tested artifact, not a standalone application executable.

## Release policy

The runner hashes execution logs/results/provenance and assembles addon-evidence.json. tools/assert-release.ts requires every current stage PASS, clean matching source, exact approved engine identity, hashed execution reports/logs and summary/report agreement. Missing, dirty, mismatched, forged or unexpected-failure evidence fails closed. There are no automatic legacy development exceptions; development-policy.ts uses the same requirement policy. Policy tests exercise these negative paths. Each artifact assesses one approved engine; actual two-engine release review requires both matching candidate-source reports:

~~~sh
corepack yarn@1.22.22 node --experimental-strip-types tools/assert-release.ts \
  /evidence/4.0.4/addon-evidence.json /evidence/4.7/addon-evidence.json
~~~

Standalone executable export, the deleted surface/JSON scenes, RefCounted helpers/callbacks and obsolete raw-string fixtures are no longer product requirements (#83). Their archived FAIL/BLOCKED/UNTESTED outcomes remain unchanged. Any genuine current native-product failure remains a blocker until fixed or explicitly scoped by owner decision; do not suppress native errors or label them PASS. Green checks do not authorize automatic publishing/merging or certify untested minor/platform support. No publisher exists.

Current C4 issue/PR records exact source/engine provenance, commands, actual outcomes and captures. [C3 archival evidence](../tests/compatibility/c3/README.md) records the prior native slice under transitional paths; it is not fresh C4 evidence.

## Native addon pack format / Godot 4.0 exporter bridge

The sample project explicitly sets `editor/export/convert_text_resources_to_binary=false`. The pack retains native textual scenes/resources (and generated GDScript), then tests them from a separate bare process. In official Godot 4.0.4, `_export_customize` instantiates scene roots for binary conversion without freeing them; verbose output identifies leaked Counter/2D/3D roots, GDScript/SceneState resources and a canvas RID. The [official 4.0.4 source](https://github.com/godotengine/godot/blob/4.0.4-stable/editor/export/editor_export_platform.cpp#L742) shows that path; the early-return supported text-resource path avoids it. This is a small project export-setting bridge, not an engine patch or error exemption. Consumers exporting with 4.0.4 should retain this setting for Estragon scenes until their own export/cleanup evidence supports another format. Both approved engines verify actual editor pack export and runtime with this explicit format. Binary-conversion export is not claimed fixed or certified; its original #65 failure remains archival evidence.
