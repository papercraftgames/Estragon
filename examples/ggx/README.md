# C2 Gogo-authored native GGX

Open the project with **official Godot 4.0.4 or pinned 4.7.0**, enable the
Estragon addon, then open and run either scene:

- `res://examples/ggx/TwoD.tscn` — authored `TwoD.gogo`
- `res://examples/ggx/ThreeD.tscn` — authored `ThreeD.gogo`

Press Enter to emit the native Timer signal: the first allocation grows and the
purple native sibling moves, preserving Node identity. Both scenes use the real
C1 runtime. Polygon2D/mesh rendering remains Godot's; no C3 widgets are implied.
The Gogo files preload custom Node scripts and C1 entry/adapters, return virtual Element descriptions from typed build_view functions and reconcile retained native
children, connect a named Timer handler through GGX, and connect/disconnect a
referenced Gradient.changed signal in ordinary authored Gogo methods.

Edit/save `.gogo`, or Play with unsaved edits: the **normal bundled Godot plugin**
builds and semantically validates current sources, including these configured
source roots. Invalid/unsavable edits block F5 and F6; repair then Play recovers.
No Bun/Yarn/Node/compiler command or manually edited generated file is required.
Checked generated scripts let the scenes resolve on initial open; compiler output
is derived from authored `.gogo`. Current strict acceptance covers fresh/source-only cold restoration on both approved Linux engines; exact outcomes are in the active issue/PR.

Canonical UI components are EstragonRect/Text/Button/HBox/VBox. Use native class names or explicit unambiguous preload aliases; Button retains Godot semantics. No legacy short-tag factories, namespace pragmas or custom child-adders remain. See ../../docs/GOGO_LANGUAGE.md and ../../docs/TESTING.md for current authoring/acceptance; C2 evidence is historical.
