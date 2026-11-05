# Reactive native model demo

Enable the bundled addon and run `Demo.tscn`. `advance()` changes a typed nested RefCounted model’s title/tint/width and the host count; the same native Nodes update without refresh/rebuild or hand-wired observers. Tests call it and capture initial/changed/resized frames. The Counter supplies interactive buttons using the same compiler/runtime. See [contract](../../docs/REACTIVE_GGX.md) for dynamic getter reads, coalesced composition, explicit nullable fallback and lifetime rules. Eager factories and target-owned binders are removed in F04.
