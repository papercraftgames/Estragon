# Reactive native model demo

Enable the bundled addon and run `Demo.tscn`. `advance()` changes a typed nested RefCounted model’s title/tint/width and the host count; the same native Nodes update without refresh/rebuild or hand-wired observers. Tests call it and capture initial/changed/resized frames. The Counter supplies interactive buttons using the same compiler/runtime. See [contract](../../docs/REACTIVE_GGX.md) for explicit self paths, deferred batching/null/lifetime rules and unsupported forms.
