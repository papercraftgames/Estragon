# EL02 — reusable GGX layout declarations

Issue [#192](https://github.com/papercraftgames/Estragon/issues/192),
[ADR-0030](DECISIONS.md#adr-0030--lexical-layout-presets-over-native-grid).
Run `examples/layouts/Layouts.tscn` for the authored native gallery.

```gogo
layout const <Side gap="8px">
    <Top /> <Top /> <Top />
    <BottomLeft /> <BottomMiddle /> <BottomRight />
</Side>

layout const <App gap="8px" columns={["160px", "1fr"]}>
    <Header /> <Header />
    <Side width="25%" /> <Body />
    <Side /> <Footer />
</App>
```

These statements declare definitions; they mount nothing. Opening-tag source
lines delimit matrix rows. Empty tags on the same line occupy successive cells;
attributes may span lines. Each exact, case-sensitive identifier introduces one
binding. The App matrix is `Header Header`, `Side Body`, `Side Footer`.
Repeated tags describe spans, with rectangular/equal-width validation through the
existing GridDefinition. They do not describe repeated rendered children.
Actual `<App><Header /><Side />...</App>` use sites produce fresh Elements and,
on mount, ordinary native Nodes. Repeated uses in different trees are independent.

Both `layout const` and `layout var` work at module/function/block scope; a later
layout declaration resolves its base before introducing new versions of its root
and unique areas. Subsequent references in the enclosing lexical scope see the
new versions. Earlier references, enclosing/sibling scopes and imported values
retain their previous bindings. Native function parameters/local declarations
hide earlier names. No PascalCase conversion, global registration or mutation of
an older component/constant occurs. `const` rejects subsequent direct assignment;
`var` accepts assignment to another preset or constructible native Node Script/
class value. Like ordinary unannotated Gogo variables, assigning a layout var is
not itself an observable signal. Bindable properties read by defaults are observed.

Unknown declaration names receive Grid roots and Box areas. A resolved existing
component is composed with its original native type, custom properties, signals,
inheritance and child behavior. A root base must already support Grid; composing
an ordinary Box/Control as a root diagnoses the incompatible base. Areas may be
ordinary Gogo components or bounded native Controls. Import qualified native types
under an explicit ordinary preload alias. Declaration binding/area names must be
unqualified, non-keyword Gogo identifiers; lowercase names are valid. Named inner
classes retain the existing GGX restrictions. Presets are description values,
not native Node types or constructors; use GGX to instantiate them.

## Defaults and tracks

Every writable base property and ordinary named-handler/Callable signal can be
preset. The same native compiler and whole-description preflight validate values.
`key` and `bind:value` remain explicit use-site controls. Duplicate properties
within one occurrence reject; repeated occurrences merge complementary defaults.
Conflicting quoted attribute/numeric/Bool/null constant defaults reject at compile time. Other
expressions and ordered Dictionary spreads are evaluated once per authored
occurrence at use, inside the caller's existing getter-observation scope, then
compared by native type/value across occurrences. Unequal repeats reject the
whole desired transaction with declaration provenance; they never silently win.
Within one occurrence, normal S03 spread ordering applies. Instance properties,
spreads and handlers override the combined defaults. Removed spread defaults use
the existing native reset path. Raw in-place collection mutation remains unobserved.

The compiler supplies default `direction="grid"`, `columns`, `rows=null`,
`areas` and `template=""`. Explicit defaults and instance properties can override
these; existing Grid validation remains authoritative. Use actual `columns`/
`rows` track arrays or `template` for track sizes. A default nonempty `template`
must retain the declared matrix, and replaces the generated structured tracks;
explicit conflicting structured/template properties still reject normally. A use-site
nonempty template replaces the preset structured defaults; explicit conflicting
use-site tracks still reject through normal native preflight.

`width`/`height` are ordinary dimensions, never track declarations. **Existing
Grid child percentages use the full immediate Grid content reference, not the
cell** ([shipped contract](RESPONSIVE_LAYOUT.md)). #192's cell-relative wording
differs from that implementation; EL02 preserves its separately requested existing
percentage behavior. Use `width="auto"` for cell stretch. The gallery's composed
Side defaults to25%, then overrides it with auto at its use site; its column stays
160px. Nothing in the preset rewrites percentages or implements another solver.

Grid now extends Box and accepts `direction="grid"`, `"row"`, `"column"`.
Only Grid-capable types accept grid mode. Row/column use the existing stack/wrap
policy; columns/rows/areas/template remain stored and become active again in grid
mode. A child's direction governs its own children; logical parent placement stays
external and unchanged. Main-axis stretch defaults normalize to start on leaving
grid mode; explicit illegal physical alignment values still reject. Track storage
precedes dependent areas/template during native PackedScene restoration.

## Exports and cross-file reuse

`export layout const/var` is module-scope syntax. Gogo uses native Script/host
instances, not ES module evaluation. Export exposes each binding as a public native
host **instance property**: const has a getter, var also has a setter. Unexported
bindings have hygienic private storage. An exported native/global class spelling
rejects; use a local alias. Repeated exports expose the last exported version while
previously resolved uses keep their own versions.

```gogo
# Library.gogo may extend RefCounted: it is a value, never a hidden scene Node.
export layout const <Shared><upper /> <upper /></Shared>

# Consumer.gogo — actual generated Script preload paths as usual.
const Library = preload("Library.gd")
var library: Library = Library.new()
var Shared = library.Shared
layout const <Panel><Shared /></Panel>
func view():
    return <Panel><Shared><library.upper /></Shared></Panel>
```

A typed receiver's two-part `<library.Shared>`/`<library.upper>` tag resolves
exported authored metadata; no exporting host is instantiated by the compiler.
A normal `var Shared = library.Shared` alias can be recomposed locally. Keep the
library instance alive while its dynamic defaults are used. Module default
methods are weak native Callables, avoiding RefCounted owner/preset closure
cycles; a disposed default scope rejects safely. Function-local defaults use
normal GDScript closure capture. Arbitrary receiver chains, untyped receivers,
static `Library.Shared` access, unexported bindings and circular exported
composition diagnose rather than inventing native module semantics.

Top/BottomLeft/etc. introduced by Side remain bindings of Side's declaration's
enclosing scope. Composing Side in App only introduces App and App's own unique
area names; it does not redeclare Side's internal names. Export them explicitly
from the original declaration to reuse them across host instances/files.

## Native lowering

Conceptually, with hygienic names and mapped authored expressions:

```gdscript
var _side_0 = Preset.new(Grid, Callable(self, "_side_defaults"),
    {"direction":"grid", "columns":3, "rows":null,
     "areas":["Top Top Top", "BottomLeft BottomMiddle BottomRight"], "template":""}, source)
var _side_1 = Preset.new(_side_0, Callable(self, "_area_defaults"), {"area":"Side"}, source)
func _side_defaults(): return [[["gap", "8px", origin]]]
func _area_defaults(): return [[["width", "25%", origin]], []]
# Each actual use evaluates defaults in the existing composition read scope:
# Preset.apply(_side_1, Element.new(Preset.type_of(_side_1), instance_props, ...))
```

`runtime/composition/preset.gd` merges description defaults and logical placement;
`Element`/Computation perform their existing complete-tree validation, native
construction, signal connection and retained reconciliation. GridDefinition,
GridPolicy and layout_core remain the sole geometry path. There are no generated
adapter scripts, wrapper Nodes, node metadata/fibers, helper Nodes or idle render
loops. Every emitted range, including default methods, maps to authored spans.

Focused proof is collected by `tools/check-layouts.ts --editor` through immutable
direct Yarn installation on official Linux4.0.4/pinned4.7.0. Live #192/its sole PR
and [evidence](evidence/EL02_LAYOUT_DECLARATIONS.md) determine verification/review
status. This does not implement EL01 responsive recipes or its visual designer.
