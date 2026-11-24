extends SceneTree
const Compiler=preload("res://addons/estragon/compiler/compiler.gd")
var checks:=0
var errors:=0
func check(value: bool,label: String):
    checks+=1
    print("CORE02_FRONTEND ",label,": ",value)
    if not value: errors+=1
func compile(text: String):
    return Compiler.compile(text,"res://examples/data/Probe.gogo","res://examples/data/generated/Probe.gd")
func native(result):
    var script=GDScript.new()
    script.resource_path="res://examples/data/generated/Probe"+str(checks)+".gd"
    script.source_code=result.code
    check(script.reload()==OK,"native 4.0-compatible emitted semantics")
    return script
func _initialize():
    var imports='extends RefCounted\nconst Item=preload("Item.gd")\n'
    var result=compile(imports+'''var item: Item = {"id":9}
func run() -> bool:
    var value: Item = {
        "id":3,
        "details":{"note":"multiline"}
    }
    value = {"id":4}
    value.details.tags = ["nested"]
    self.item = {"id":10}
    return value.id==4 and value.details.tags.at(0)=="nested" and item.id==10
func unrelated() -> bool:
    var value: Dictionary = {}
    value = {"unchanged":true}
    return value.unchanged
func parameter(value: Item) -> void:
    value.details = {"note":"parameter"}
''')
    check(result.ok,"typed declarations, reassignment, nested members and self member")
    if result.ok:
        var instance=native(result).new()
        check(instance.run() and instance.unrelated(),"hydration executes and sibling lexical shadow remains native")
        instance.parameter(instance.item)
        check(instance.item.details.note=="parameter","typed parameter member boundary hydrates")
    result=compile(imports+'''func run() -> bool:
    var values: ArrayCollection[Item] = [{"id":1}]
    var total: int = 0
    for value in values: total+=value.id
    values.append({"id":2})
    return total==1 and values.size()==2 and values.at(1).id==2
''')
    check(result.ok,"typed local collection lowers")
    if result.ok: check(native(result).new().run(),"native collection iteration and insertion hydration")
    for member in ['func to_data():\n    pass\n','signal _gogo_data_changed\n']:
        result=compile('@bindable\nextends RefCounted\nvar count: int\n'+member)
        check(not result.ok and result.diagnostics[0].format().contains('Probe.gogo:'),"authored reserved-method/signal collision diagnostic")
    result=compile('@bindable\nextends RefCounted\nvar value: int\nvar title: String\n')
    if result.ok:
        var model=native(result).new()
        check(model.to_data()=={"value":0,"title":""},"uninitialized fields keep native typed defaults")
    result=compile('@bindable\nextends "Item.gd"\nvar extra: int=7\n')
    check(result.ok,"inherited data shape compiles")
    if result.ok:
        var model=native(result).new()
        check(model.to_data().extra==7 and model.to_data().quantity==1,"inherited fields and defaults serialize")
    result=compile('@bindable\nextends RefCounted\nvar labels: Array[String]=["default"]\nvar notices: int=0\nfunc _notification(what: int) -> void:\n    if what==999: notices+=1\n')
    if result.ok:
        var script=native(result)
        var converted=preload("res://addons/estragon/runtime/data/state.tres").hydrate({"labels":["one","two"]},script)
        check(converted.ok and converted.value.labels is Array[String],"native typed Array fields hydrate atomically and stay native")
        converted.value.notification(999)
        check(converted.value.notices==1,"authored notification method retained with cleanup")
        check(not preload("res://addons/estragon/runtime/data/state.tres").hydrate({"labels":[1]},script).ok,"invalid native typed Array element rejected before setter")
    print("CORE02_FRONTEND_CHECKS ",checks," ERRORS ",errors)
    if errors==0: print("CORE02_FRONTEND_OK")
    quit(0 if errors==0 else 1)
