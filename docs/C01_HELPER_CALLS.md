# C01 #61: generated static helpers inside lambdas

[#61](https://github.com/resistdesign/Estragon/issues/61) fixes generated
construction calls, not authored native-language syntax. C01-H release acceptance
remains BLOCKED by its other requirements and the independent 4.0 raw-syntax
boundary. Only official 4.0.4 and pinned 4.7.0 are used for new verification.

The original emitter generated bare static calls such as `_gogo_build_3()`.
On actual Godot 4.0.4, native reload succeeds but a lambda invoking that call
reports `Nonexistent function '_gogo_build_3' in base 'Nil'` and returns null.
A raw-string-free Gogo fixture reproduces this independently of HybridEdges.
Reload-only success cannot prove this behavior correct.

Hybrid factories now live in a compiler-owned `_GogoFactories_N` class, selected
against all authored identifiers. Generated calls explicitly qualify that class,
e.g. `_GogoFactories_1._gogo_build_3((7.0))`. Every helper remains a native static
method with typed parameters and return values. There is no blanket `self`
qualification, untyped Callable invocation, runtime interpreter or change to
application ownership. The native/reference emitters use the same ordering,
indentation and mapped ranges. Standalone markup output is unchanged.

Dynamic arguments are still evaluated once in authored scope, in source traversal
order. Nested/lazy expressions remain native GDScript. The emitter never moves
or rewrites authored source to infer static/instance/lambda contexts. Explicit
qualification covers method bodies, member initializers and nested lambdas
without maintaining an additional GDScript scope parser. Generated class/helper
identifiers avoid authored collisions; base/derived modules are exercised.
Callback values are passed unchanged to the existing guards/connections, with
normal owner cleanup and target identity preserved.

## Verification

`tests/fixtures/helper-calls.gogo` has no raw strings. The native execution driver
checks actual returned components/values for instance/static methods and lambdas,
member/lambda initializers, nested captured arguments and nested components;
authored [1,2,3] side-effect order; independent generated base/derived factories;
original Button Callable identity and owner disposal; deterministic output and
source maps, exact copied source and qualified-call locations. Separate native
negative processes require wrong-argument and wrong-return type rejection with
exact diagnostic counts, plus authored line mapping. These gates are required
in both scoped compatibility and strict release policy, independent of
`hybrid_runtime`.

```sh
node --experimental-strip-types tools/check-helper-calls.ts --engine 4.0.4=/absolute/godot-4.0.4 --engine 4.7=/absolute/godot-4.7.0 --output /new/helper-results
bun install --frozen-lockfile
bun run check
node --experimental-strip-types --test tests/compatibility/*.test.ts
GODOT_BIN=/absolute/pinned/godot sh tools/check-native-generation.sh
```

The standalone TypeScript harness copies verified official engines into isolated
self-contained projects with an empty tool PATH. It is contributor tooling;
normal compilation/Play still uses only Godot and the bundled native addon.
Native/reference output/map parity also includes the raw-free fixture; checked-in
Mixed/Counter code/maps and reference transcript are regenerated, not hand-edited.
Use focused checks during development and the bounded approved-engine review
pass, not archived nine-engine reruns. Native editor/graphics evidence is
separate from headless results; physical-key testing is not required.

## Remaining boundaries

HybridEdges still contains an authored raw string unsupported by Godot 4.0.4.
This PR neither modifies that fixture nor marks full `hybrid_runtime` PASS from
the raw-free helper result. The independent raw-syntax decision is recorded on
[#51](https://github.com/resistdesign/Estragon/issues/51). Ordinary GDScript
semantics, including old-engine limitations when a lambda reads a bare method
value, are not rewritten; the callback test explicitly captures a normal
`Callable(self, "on_pressed")` before constructing the lambda.

The #44 hidden-tab exception, cold missing-generated-scene behavior, #65 export
cleanup, standalone export/platform scope and T09 remain separate. Development
CI may accept only its measured documented blockers; strict release gating still
fails closed. No new release exception or support certification is made here.

## Recorded results and exact source revisions

[Artifacts and checksums](../tests/compatibility/c61/) preserve the raw-free main
reproducer at b1e252c (new test fixture/harness only, explicitly dirty), then
clean 32a5f4c acceptance on actual 4.0.4 and 4.7.0: **47 positive assertions per
engine and both native negative typing processes PASS**. The emitter/harness
source hashes and official input binary/version hashes are recorded. The baseline
fixture/driver/tool snapshots are included so the original failure is reproducible
without chat context.

Broader 4.7 generation initially found native/reference guard-indentation parity
failure. The failed log is retained; 24b22c corrects the one-level guard indentation
inside generated classes. The repeated affected generation suite then passes
**3670 generation/map assertions**, seven reference fixtures, generated layout,
HybridEdges, Counter/signals and **149 native semantic assertions**, with numeric
checks. This is not relabeled execution of 32a5f4c or a third engine.

The isolated native graphical 4.7 editor suite at 32a5f4c also passes automatic
highlighting, newest unsaved F5/F6, generated callbacks/input/resize, transactional
identity/rollback and restart, including 32 native build assertions. Native editor
and Count 1/reset-resized captures were inspected; logs and selected PNGs are
committed. The later indentation-only parity correction does not turn these
earlier captures into execution of a newer revision. No manual smoke/physical-key
test was performed; automated graphical evidence is separate from headless checks.

Reference verification: locked install plus bun run check PASS (**202 tests**,
typecheck and IR/GDScript/map consistency); **21** TypeScript evidence/policy
controls PASS. A new required helper_calls and two helper_negative stages in
compatibility/release policy ensure a full HybridEdges raw-string failure cannot
mask regression of this scoped fix. Final-head CI and actual full hybrid/release
outcomes are linked in #61 and its PR handoff; no overall release PASS is claimed.
