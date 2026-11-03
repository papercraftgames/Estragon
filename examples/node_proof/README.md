# Native GGX Node composition proof (B1)

This tiny example exercises the **explicit B1 compiler API**, not the default editor compiler. It constructs actual ordinary/custom Node2D and Node3D children, passes native properties and Resources, and connects a native Timer signal. No layout entries, native layout adapters, bindings or migrated Estragon runtime are implemented.

From the repository/project directory, build with **Godot alone**:

```sh
/absolute/path/to/godot --headless --path . --script res://examples/node_proof/build.gd
```

Use only official Godot 4.0.4 or pinned 4.7.0 for current verification. This writes validated `generated/Composition.gd` and its map from [.proof/Composition.gogo](.proof/Composition.gogo). The generated output is checked in for inspection/Play; rebuild after editing the source. The explicit builder blocks invalid output and restores previous files/cache on failure. No Bun, Node.js, Yarn or executable compiler setup is needed for this build.

Open `res://examples/node_proof/Main.tscn` in Godot and run that scene. A teal Polygon2D appears. Press Enter/Space; a native Timer fires once after half a second and the generated named-handler connection turns the polygon purple. Inspect the Remote tree beneath `NativeGGXProof/Composition`: `Panel` is a custom Node2D, `Pulse` is an ordinary Timer, and `Boundary/Space` is a custom Node3D with native Node3D/MeshInstance3D descendants. There is no 3D camera; this scene demonstrates 3D composition/transforms, not rendered 3D layout. Automated acceptance triggers the Timer without physical keypresses.

The referenced Gradient's `changed` signal is connected directly in authored Gogo code on entry and disconnected on exit. All native property/handler expressions are construction-time. The `.proof` folder is hidden so the ordinary Gogo source scanner does not accidentally select this opt-in experimental syntax. The existing Counter and compiler remain unchanged.

Read [the proof contract and evidence](../../docs/NODE_COMPOSITION_PROOF.md) for bounded types, parentage versus PackedScene owner policy, persistence, native cleanup, transform boundaries and limitations. The full Node-native framework is not shipped; strict C01 release remains **BLOCKED**.
