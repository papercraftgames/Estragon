# D07 — Import-selected Button

Gogo selects the explicit Script import in the current source:

```gogo
const Element = preload("../../../addons/estragon/runtime/composition/element.gd")
const Button = preload("../../../addons/estragon/runtime/node/button.gd")
func build_view() -> Element:
    return <Button pressed={exit}>Exit</Button>
func exit(): get_tree().quit()
```

Paths above are relative to an `examples/.../generated` destination. Installed
projects use their actual `node_modules/@papercraftgames/estragon/addons/estragon`
location; editor completion computes that relative path. No implicit framework
import exists. In a different source without that preload, `<Button>` and
`Button.new()` retain Godot's native Control meaning.

Both approved engines reject a literal GDScript `const Button` declaration.
The compiler therefore lowers explicit native-name Script preload identifiers
through lexical token spans to collision-free private symbols. GGX tags,
constructors, type hints, bindable field types and ordinary alias expressions
share the selected Script identity. Generated symbols map back to authored
identifier spans. Comments, strings and unrelated `object.Button` members are
unchanged. Redeclaring an imported name is rejected; this is not a new local
shadowing facility. Project component ambiguity, invalid Resources and missing
or nonconstructible imports still fail closed. There is no class registration,
namespace or alternate reactive runtime.

For both kinds in one source, use an ordinary authored native Script:

```gdscript
# godot_button.gd: no colliding import in this source.
@tool
extends Button
```

Then import it as `NativeButton` alongside the Estragon `Button` import. The
[runnable Buttons example](../examples/button_imports/Buttons.gogo) demonstrates
both this native Control alias and an unimported native Button in a separate
Gogo component. `ClassDB.instantiate("Button")` is also an explicit native
constructor. `const Other = Button` in the imported source aliases the imported
Script; it does not snapshot the native class.

Completion distinguishes **Godot** from **Estragon native; explicit import**.
Choosing the latter inserts the Button preload and tag in one undo operation.
Add Missing Imports leaves bare native Button tags alone. Removing the import
restores native field completion. Existing user `const UiButton = preload(...)`
aliases continue to work as ordinary explicit imports; the official catalog and
new examples do not recommend a prefix. `class_name EstragonButton` is unchanged.

New unstyled Estragon Buttons use normal `#383838`, hover `#505050`, pressed
`#252525`, disabled `#303030`, including the initial style cache. Unchecked
Toggle uses charcoal; checked Toggle retains `#227a60` and underline `#65f4b0`.
Disabled color takes precedence. White text, half-alpha disabled text,14/8
padding, square defaults and explicit S04 surfaces remain unchanged. Native
Godot Button retains its engine theme and GUI behavior. Local custom/spread
colors remain authoritative and palette changes do not invalidate layout.

Historical L04/S02/S04 evidence records the names and palette tested at that
time. D07 verification is separate; it does not rewrite those historical facts.
