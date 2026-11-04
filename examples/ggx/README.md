# C2 Gogo-authored native GGX

Open the project with **official Godot 4.0.4 or pinned 4.7.0**, enable the
Estragon addon, then open and run either scene:

- `res://examples/ggx/TwoD.tscn` — authored `TwoD.gogo`
- `res://examples/ggx/ThreeD.tscn` — authored `ThreeD.gogo`

Press Enter to emit the native Timer signal: the first allocation grows and the
purple native sibling moves, preserving Node identity. Both scenes use the real
C1 runtime. Polygon2D/mesh rendering remains Godot's; no C3 widgets are implied.
The Gogo files preload custom Node scripts and C1 entry/adapters, compose native
children, connect a named Timer handler through GGX, and connect/disconnect a
referenced Gradient.changed signal in ordinary authored Gogo methods.

Edit/save `.gogo`, or Play with unsaved edits: the **normal bundled Godot plugin**
builds and semantically validates current sources, including these configured
source roots. Invalid/unsavable edits block F5 and F6; repair then Play recovers.
No Bun/Yarn/Node/compiler command or manually edited generated file is required.
Checked generated scripts let the scenes resolve on initial open; compiler output
is derived from authored `.gogo`. The existing older-engine cold missing-generated
scene issue remains tracked under C01; this demo does not claim that release fix.

Short legacy names VBox/HBox/Rect/Text/Button retain their existing RefCounted
semantics and inline callbacks. Native trees use other Godot class names,
registered C1 classes or top-level `const Alias = preload("res://...gd")` aliases.
Never mix legacy and native tree children. Values/resources stay in expression
properties, not hierarchy tags. Native event attributes use named/Callable
references, not inline function declarations. See the [C2 language contract](../../docs/NODE_GGX.md).
