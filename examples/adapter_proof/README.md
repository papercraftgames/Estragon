# B3 native adapters (experimental)

Open `TwoD.tscn` or `ThreeD.tscn` in Godot 4.0.4 / pinned 4.7.0 and run that scene.
Two real Polygon2D / MeshInstance3D children are placed by B2's shared row layout.
Press Enter to change geometry; resize the window to inspect the native view.
No external build, Bun or Node installation is needed. Scenes run directly.

The demo owns native geometry and transforms; adapters measure transformed bounds
and own wrapper translation. Set adapter width/height/depth to >= 0 for a fixed
allocation (no stretching); -1 uses native bounds. After geometry, transform or
mesh replacement, call `invalidate_native()`. Mesh.changed observation is opt-in;
Polygon2D edits require explicit invalidation. Native child ownership is explicit
for saved scenes. See [contract and limits](../../docs/NODE_ADAPTER_PROOF.md).
