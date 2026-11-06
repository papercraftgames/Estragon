# Release notes

## 0.1.0-beta.2 — next trusted-publisher beta

Release preparation only; no framework/runtime behavior changes since beta.1. Bumps package and native Godot plugin versions together and updates public installation/release documentation. The owner-controlled GitHub prerelease `v0.1.0-beta.2` will exercise npm OIDC trusted publishing, provenance, exact package bytes, and fresh Linux Godot 4.0.4/4.7.0 registry consumer checks. No CI publication or validation is claimed until that release workflow actually completes.

## 0.1.0-beta.1 — first public beta (2026-11-06, local npm publication)

First curated `@papercraftgames/estragon` native Godot addon artifact after merged F01–F06. Includes bundled Gogo/GGX compiler/editor, typed/class-wide bindables, one signal-driven description reconciler, conditional/keyed retained Nodes, native boolean two-way toggle, layout-first 2D widgets and bounded 3D adapters, opt-in profiling and measured LIS/preflight improvements.

No JavaScript compiler/runtime or lifecycle scripts. Yarn dependency acquisition requires an explicit copy to project addons/estragon and node_modules/.gdignore. This is a pre-1.0 slice, not full UI framework/release certification. Exact verified source/engines/artifacts and limitations are recorded in issue #104 and the packaging PR.
