class_name BindableExampleModel
extends RefCounted
## Typed non-Node data; GGX and UI dependency bindings are unnecessary here.
signal count_changed(previous: int, value: int)
var count: int = 3:
    set(_gogo_incoming_count):
        if is_same(count, _gogo_incoming_count): return
        var _gogo_previous_count: int = count
        count = _gogo_incoming_count
        count_changed.emit(_gogo_previous_count, _gogo_incoming_count)

signal title_changed(previous: String, value: String)
var title: String = "Model":
    set(_gogo_incoming_title):
        if is_same(title, _gogo_incoming_title): return
        var _gogo_previous_title: String = title
        title = _gogo_incoming_title
        title_changed.emit(_gogo_previous_title, _gogo_incoming_title)

signal items_changed(previous: Array[int], value: Array[int])
var items: Array[int] = []:
    set(_gogo_incoming_items):
        if is_same(items, _gogo_incoming_items): return
        var _gogo_previous_items: Array[int] = items
        items = _gogo_incoming_items
        items_changed.emit(_gogo_previous_items, _gogo_incoming_items)

signal peer_changed(previous: RefCounted, value: RefCounted)
var peer: RefCounted = null:
    set(_gogo_incoming_peer):
        if is_same(peer, _gogo_incoming_peer): return
        var _gogo_previous_peer: RefCounted = peer
        peer = _gogo_incoming_peer
        peer_changed.emit(_gogo_previous_peer, _gogo_incoming_peer)

signal amount_changed(previous: float, value: float)
var amount: float = 0.0:
    set(_gogo_incoming_amount):
        if is_same(amount, _gogo_incoming_amount): return
        var _gogo_previous_amount: float = amount
        amount = _gogo_incoming_amount
        amount_changed.emit(_gogo_previous_amount, _gogo_incoming_amount)

func increment() -> void:
    count += 1

