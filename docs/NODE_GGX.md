# Native GGX compiler contract

C2 PR #80 introduced normal native GGX; C4 #83 removes legacy selector/factory/leaf/callback paths. The current contract is [GOGO_LANGUAGE](GOGO_LANGUAGE.md), [UI API](NODE_UI.md) and [architecture](ARCHITECTURE.md). Author GDScript-first modules, use native/canonical registered Node classes or explicit unambiguous preload aliases, native typed props, named Callables and inherited void Node.add_child. Button means Godot Button; EstragonButton is the framework widget. No inline anonymous GGX event declarations, non-Node children, expression adoption, custom child-adders or implicit short-tag factories.

The same bundled parser, deterministic typed factory emitter/maps, static native resolver and actual-path transactional semantic validator serve normal editor builds. Code-only non-Node Gogo models remain valid. Compiler analysis/codegen never needs a running SceneTree/editor/renderer or external toolchain. Normal editor save/unsaved main/current Play failure/repair and source-authored native 2D/3D demos are current acceptance. See [TESTING](TESTING.md).

C2 historical commands, provenance, limits and captures are preserved under tests/compatibility/c2; they retain their exact old paths/outcomes and are not instructions to restore retired compatibility. Broader imports/adoption/bindings remain future work.
