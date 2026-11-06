# Release notes

## Next automated prerelease

No compiler/runtime behavior changes are introduced by the packaging and version-source correction. The **one** release version is set in the Godot plugin configuration; the npm manifest is generated from it during packaging. The owner-controlled GitHub prerelease will exercise npm OIDC trusted publishing, provenance, byte-for-byte package verification and the approved Linux Godot consumer checks. These publication checks remain pending until the release actually runs.

## Initial public beta

The first curated `@papercraftgames/estragon` addon artifact was published locally after merged F01–F06. It includes the bundled Gogo/GGX compiler/editor, typed/class-wide bindables, a signal-driven description reconciler, conditional/keyed retained Nodes, a native boolean two-way toggle, layout-first 2D widgets, bounded 3D adapters, opt-in profiling and measured LIS/preflight improvements.

No JavaScript compiler/runtime or lifecycle scripts. Yarn dependency acquisition requires an explicit copy to the Godot project's `addons/estragon` and a `node_modules/.gdignore`. This is an early beta, not complete UI framework or release certification. Verified source/engines/artifact evidence and limitations remain in issue #104.
