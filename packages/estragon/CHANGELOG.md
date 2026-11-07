# Release notes

## Gogo editor experience — upcoming beta

The native Gogo editor now provides theme-aware GDScript/GGX syntax highlighting, context-sensitive CodeEdit completion and insertion/undo, source-positioned diagnostics/navigation, and **Project > Tools > New Gogo Script** templates for 2D/3D. No external compiler, language server or custom Godot build is needed for editing and Play. Dedicated native editor and Play checks passed on the two approved Linux Godot engines. Completion intentionally supports bounded lexical/ClassDB information rather than full GDScript type inference; the documented hidden, never-associated tab exception remains.

## Previous direct Yarn installation beta

P02 made compiler/runtime/editor dependencies location-independent: packages work directly from Yarn `node_modules` without addon copying/symlinks. Internal references and generated dependencies resolve against installed Resources and actual destinations; Godot's enabled-plugin project setting accepts the full addon configuration path. That previous beta was published using the owner-controlled GitHub prerelease, with npm trusted-publisher OIDC, provenance/byte checks and native registry consumers. CI02 subsequently reduced mandatory certification to bounded direct-install validation; the full native regression suite remains opt-in.

## Initial public beta

The first curated `@papercraftgames/estragon` addon artifact was published locally after merged F01–F06. It includes the bundled Gogo/GGX compiler/editor, typed/class-wide bindables, a signal-driven description reconciler, conditional/keyed retained Nodes, a native boolean two-way toggle, layout-first 2D widgets, bounded 3D adapters, opt-in profiling and measured LIS/preflight improvements.

No JavaScript compiler/runtime or lifecycle scripts. The initial artifact used the former relocated-addon install contract; P02 replaces it with direct Yarn consumption. This is an early beta, not complete UI framework or release certification. Verified source/engines/artifact evidence and limitations remain in issue #104.
