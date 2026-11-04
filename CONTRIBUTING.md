# Contributing

Read [AGENTS.md](AGENTS.md), the live task issue/PR and [WORK_STATUS](docs/WORK_STATUS.md). One open PR total; implement one scoped issue, post a concrete plan before edits, checkpoints and exact evidence, then a durable handoff. Owner reviews/merges manually. Do not begin a successor while the PR is open.

Production is bundled native Godot/Gogo. New contributor automation is TypeScript/Yarn; no Python or external end-user compiler. Use the two approved official Linux engines only, focused development then proportionate acceptance. [TESTING](docs/TESTING.md) defines policy/typecheck, native runtime/editor/graphics/distribution and strict addon release checks. No physical-key or standalone-app export gate.

Run the default native Counter scene, author examples/counter/Counter.gogo and inspect examples/ggx 2D/3D scenes. Use canonical native API/normal explicit imports; do not add retired compatibility shims, private child trees or Error-returning Node adders. Preserve original Assets, native instance/Script identity, source maps, failure rollback and user editor preferences.

Keep every committed .gd paired with stable .gd.uid, including tests/generated examples. Preserve real asset .import settings. Rename/delete sidecars with their source; never copy arbitrary runner UID files or blanket-ignore UID/import suffixes. Test clean imports and uniqueness. Only .godot/cache paths are disposable. Audited archival evidence/research directories may carry narrow .gdignore files; never hide live fixtures. Native editor tests run in copied self-contained projects/settings, never the owner's preferences.

Provide a reviewable PR with one work ID, linked issue, behavior/non-goals, exact commands/CI links, source+engine evidence and actual untested/failed outcomes. Current product gates replace discontinued requirements; preserve old reports as history rather than rewriting outcomes. No automatic merge or release.
