# Observable non-Node Gogo model

Open `Demo.tscn` in Godot with the bundled Estragon plugin enabled, then run the scene. It prints the model's initial/final values and two actual native change callbacks. Edit the typed `@bindable` properties in `Model.gogo`; `Derived.gogo` inherits those setters/signals and adds its own property. Ordinary `model.count += 1` and `model.increment()` notify without manual refresh or polling. No external compiler setup is required.

This is a data-model demo, not automatic UI binding. The canonical Counter and 2D/3D examples remain separate; T09-B will specify reactive GGX dependencies. See [T09-A contract](../../docs/BINDABLE_PROPERTIES.md), [language](../../docs/GOGO_LANGUAGE.md) and [verification](../../docs/TESTING.md).
