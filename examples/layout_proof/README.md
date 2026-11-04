# B2: explicit pixel and world-unit layout entries

This is a bounded layout proof, not a full Estragon component/runtime migration. It uses the B1 native GGX compiler plus separate Node2D/Node3D scripts sharing one composed measure → arrange core. No B3 native layout adapters or bindings are included.

Build from authored Gogo using **Godot alone**:

```sh
/absolute/path/to/godot --headless --path . --script res://examples/layout_proof/build.gd
```

This validates and generates `generated/Layout.gd` and its source map from [.proof/Layout.gogo](.proof/Layout.gogo). Rebuild after editing the source. The hidden proof directory avoids selecting experimental tags in the default editor compiler. Godot 4.0.4 and pinned 4.7.0 are the only currently approved verification engines; no external compiler/tool setup is needed for this build.

Run either scene:

- `res://examples/layout_proof/TwoD.tscn`: pixel-unit rectangles, centered in the viewport width.
- `res://examples/layout_proof/ThreeD.tscn`: world-unit boxes with native Camera3D and directional light. The application explicitly chooses .0125 world units per viewport pixel for root width; this is not an automatic unit conversion rule.

Teal is a participating child; purple and blue form a nested participating branch. Orange is an independent entry below an ordinary native Node2D/Node3D boundary. Press Enter/Space to change teal width; the same native Nodes reposition without rebuilding. Resize the window to change root centering. The orange subtree remains independent of those layout changes; its screen projection can still respond normally to the 3D camera/viewport.

Native tests trigger mutation/resize automatically, assert exact geometry/counters/identity and capture all three states. No physical keypress acceptance check is required. Inspect the Remote tree to see actual native Nodes. [The proof contract](../../docs/NODE_LAYOUT_PROOF.md) defines fixed versus natural lengths, local coordinates, transform authority, native boundaries, 4.0 event compatibility and unresolved future design. Strict C01 release remains **BLOCKED**; B3 remains unstarted.
