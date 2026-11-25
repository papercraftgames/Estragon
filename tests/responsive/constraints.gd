extends SceneTree
## LAYOUT-01 real native allocation, dependent natural sizes and cache authority.
const Entry=preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box=preload("res://addons/estragon/runtime/node/box.gd")
const Grid=preload("res://addons/estragon/runtime/node/grid.gd")
const Rect=preload("res://addons/estragon/runtime/node/rect.gd")
const Text=preload("res://addons/estragon/runtime/node/text.gd")
const Hosts=preload("res://addons/estragon/runtime/node/internal/composition_hosts.tres")
var entry
var checks:=0
var failed:=false
func check(ok: bool,label: String):
    checks+=1
    failed=failed or not ok
    print("LAYOUT01_NATIVE ",label,": ",ok)
func near(a: float,b: float) -> bool: return absf(a-b)<0.01
func core(node): return node._get_layout_coordinator().model
func frames():
    for index in range(7): await process_frame
func make_rect(width: Variant,height: Variant):
    var node=Rect.new()
    node.width=width
    node.height=height
    return node
func make_wrap(axis: int):
    var node=Box.new()
    node.direction="row" if axis==0 else "column"
    node.wrap=true
    node.column_gap=10 if axis==0 else 8
    node.row_gap=8 if axis==0 else 10
    for index in range(3): node.add_child(make_rect(90 if axis==0 else 20,20 if axis==0 else 90))
    return node
func mount(node):
    entry.add_child(node)
    await frames()
func release(node):
    node.free()
    await frames()
func _initialize(): run.call_deferred()
func run():
    entry=Entry.new()
    entry.width=800
    entry.height=800
    root.add_child(entry)
    for axis in range(2):
        var node=make_wrap(axis)
        node.set("width" if axis==0 else "height",220)
        await mount(node)
        check(near(node.layout_size[1-axis],48),"direct220 cross48 axis"+str(axis))
        check(near(node.get_child(2).position[1-axis],28),"actual second line offset28 axis"+str(axis))
        node.set("width" if axis==0 else "height",290)
        await frames()
        check(near(node.layout_size[1-axis],20),"direct290 cross20 axis"+str(axis))
        await release(node)
        var grid=Grid.new()
        if axis==0:
            grid.width=460
            grid.height=200
            grid.columns=2
            grid.column_gap=20
        else:
            grid.width=200
            grid.height=460
            grid.columns=["auto"]
            grid.rows=["1fr","1fr"]
            grid.row_gap=20
        node=make_wrap(axis)
        grid.add_child(node)
        await mount(grid)
        check(near(node.layout_size[axis],220) and near(node.layout_size[1-axis],48),"definite Grid auto cross track uses actual220 slot axis"+str(axis))
        check(not node.requested_extent()[1-axis]>=0 and not core(node).independent_axis(1-axis),"auto cross track does not acquire parent definite authority axis"+str(axis))
        var ids: Array=[]
        for child in node.get_children(): ids.append(child.get_instance_id())
        for extent in [600,460,600,460]:
            grid.set("width" if axis==0 else "height",extent)
            await frames()
            var expected=20 if extent==600 else 48
            check(near(node.layout_size[1-axis],expected),"repeat constrained cross "+str(expected)+" axis"+str(axis))
        check(ids==node.get_children().map(func(child): return child.get_instance_id()),"resize retains native children axis"+str(axis))
        var counters=[core(grid).measure_count,core(grid).arrange_count,core(node).measure_count,core(node).arrange_count]
        grid.set("width" if axis==0 else "height",460)
        await frames()
        check(counters==[core(grid).measure_count,core(grid).arrange_count,core(node).measure_count,core(node).arrange_count],"same size and idle stay quiet axis"+str(axis))
        grid.set("columns" if axis==0 else "rows",[220])
        grid.set("width" if axis==0 else "height","auto")
        await frames()
        check(near(node.layout_size[axis],220) and near(node.layout_size[1-axis],48),"fixed track supplies authority inside auto parent axis"+str(axis))
        grid.set("columns" if axis==0 else "rows",["auto"])
        await frames()
        check(near(node.layout_size[axis],290) and near(node.layout_size[1-axis],20),"clearing fixed constraint restores natural auto track axis"+str(axis))
        check(core(node).measurement_allocation[axis]<0,"removed authority clears cached allocation axis"+str(axis))
        await release(grid)
    var grid=Grid.new()
    grid.width=460
    grid.height=200
    grid.columns=[100,100,220]
    grid.column_gap=20
    var node=make_wrap(0)
    Hosts.set_placement(node,{"row":0,"column":0,"column_span":2})
    grid.add_child(node)
    await mount(grid)
    check(near(node.layout_size.x,220) and near(node.layout_size.y,48),"spanning fixed tracks220 determine auto row48")
    node.padding_left=5
    node.padding_right=7
    node.border_left_width=2
    node.border_right_width=6
    node.padding_top=3
    node.padding_bottom=9
    node.border_top_width=4
    node.border_bottom_width=8
    node.margin_left=4
    node.margin_right=6
    await frames()
    check(near(node.layout_size.x,210) and near(node.layout_size.y,72),"asymmetric inside20/24 plus outside10 counted once")
    check(near(node.get_child(0).position.x,7) and near(node.get_child(0).position.y,7),"actual child origin includes leading border/padding once")
    node.max_height=40
    await frames()
    check(near(node.layout_size.y,40) and near(core(node).natural_extent.y,72),"explicit cross maximum caps geometry without hiding natural overflow")
    node.min_height=45
    await frames()
    check(near(node.layout_size.y,45),"authored minimum wins conflicting maximum")
    await release(grid)
    grid=Grid.new()
    var nested=Box.new()
    nested.direction="column"
    nested.horizontal_align="stretch"
    node=make_wrap(0)
    nested.add_child(node)
    grid.add_child(nested)
    await mount(grid)
    check(near(grid.layout_size.x,90) and near(node.layout_size.x,90) and near(node.layout_size.y,76),"unbounded fr floor supplies capacity through nested VBox without percentage authority")
    check(not core(node).independent_axis(0),"intrinsic fr floor capacity remains separate from percentage authority")
    await release(grid)
    var scroller=Box.new()
    scroller.direction="column"
    scroller.width=100
    scroller.height=160
    scroller.vertical_scroll=true
    node=make_wrap(1)
    scroller.add_child(node)
    await mount(scroller)
    check(near(node.layout_size.x,20) and near(node.layout_size.y,290),"scrolling main axis remains unbounded for auto Wrap capacity")
    await release(scroller)
    var body=Box.new()
    body.direction="column"
    body.width=210
    body.height=160
    body.padding=20
    body.vertical_scroll=true
    body.scrollbar_size=12
    node=make_wrap(0)
    node.width="100%"
    body.add_child(node)
    await mount(body)
    check(near(node.layout_size.x,158) and near(node.layout_size.y,76),"immediate body210 minus padding40 and gutter12 yields158")
    check(near(core(node).dimension_reference.x,158),"nested percentage uses post-gutter immediate parent")
    body.vertical_scrollbar_width=20
    await frames()
    check(near(node.layout_size.x,150),"gutter change refreshes allocated basis once")
    await release(body)
    for rows in [["auto","auto"],["auto","1fr"]]:
        grid=Grid.new()
        grid.width=300
        grid.height=200
        grid.rows=rows
        grid.add_child(make_rect(20,30))
        body=Box.new()
        body.direction="column"
        body.vertical_scroll=true
        body.add_child(make_rect(20,300))
        grid.add_child(body)
        await mount(grid)
        var definite=rows[1]=="1fr"
        check(near(body.layout_size.y,170 if definite else 300),"auto vs definite fr scroll viewport "+str(definite))
        check(near(body.scroll_range.y,130 if definite else 0),"scroll range uses actual viewport "+str(definite))
        await release(grid)
    body=Box.new()
    body.direction="column"
    var text=Text.new()
    text.text="One\nTwo"
    body.add_child(text)
    var control=Button.new()
    control.text="Native minimum"
    control.custom_minimum_size=Vector2(350,33)
    body.add_child(control)
    await mount(body)
    check(body.layout_size.x>=350 and near(text.layout_size.y,text.font.get_height(text.font_size)*2),"real native minimum and explicit multiline font measurement")
    text.font_size=31
    control.custom_minimum_size=Vector2(390,45)
    await frames()
    check(body.layout_size.x>=390 and near(text.layout_size.y,text.font.get_height(31)*2),"font/native minimum event updates auto ancestor")
    var counts=[core(text).measure_count,core(body).measure_count]
    control.add_theme_font_size_override("font_size",40)
    await frames()
    check(body.layout_size.y>=text.layout_size.y+control.get_combined_minimum_size().y,"native theme change preserves true minimum")
    check(core(text).measure_count==counts[0],"unrelated fixed/native sibling change keeps Text measure cached")
    await release(body)
    node=make_wrap(0)
    node.width=220
    await mount(node)
    node.get_child(2).hide()
    await frames()
    check(near(node.layout_size.y,20),"hidden participant removes its wrap line")
    node.get_child(2).show()
    await frames()
    check(near(node.layout_size.y,48),"restored participant rebuilds current wrap lines")
    for child in node.get_children(): child.free()
    await frames()
    check(near(node.layout_size.y,0),"empty Wrap has zero natural cross extent")
    var retained=make_rect(280,20)
    node.add_child(retained)
    await frames()
    check(near(node.layout_size.x,220) and near(retained.layout_size.x,280) and near(node.content_extent.x,280),"unbreakable fixed item overflows forward without shrink")
    var other=Box.new()
    other.direction="column"
    await mount(other)
    node.remove_child(retained)
    other.add_child(retained)
    await frames()
    check(retained.get_parent()==other and near(other.layout_size.x,280) and near(node.layout_size.y,0),"native reparent detaches old measure ownership and retains item")
    await release(other)
    await release(node)
    grid=Grid.new()
    grid.columns=[220.5]
    node=make_wrap(0)
    for child in node.get_children(): child.width=90.25; child.height=20.5
    node.column_gap=10.25
    node.row_gap=8.25
    grid.add_child(node)
    await mount(grid)
    check(near(node.layout_size.x,220.5) and near(node.layout_size.y,49.25) and near(node.get_child(2).position.y,28.75),"fractional allocated constraints and physical gaps stay unrounded")
    await release(grid)
    grid=Grid.new()
    grid.width=460
    grid.columns=2
    grid.column_gap=20
    var huge=Button.new()
    huge.text="Native"
    huge.custom_minimum_size=Vector2(500,24)
    grid.add_child(huge)
    grid.add_child(make_rect(10,10))
    await mount(grid)
    check(near(huge.size.x,500) and near(core(grid).policy_result.columns[1],10),"native minimum is never shrunk to fit fr budget")
    check(near(grid.layout_size.x,460) and near(grid.content_extent.x,530),"intentional native floor overflow has explicit 530px numeric cause")
    await release(grid)
    grid=Grid.new()
    grid.width=220
    var native_label=Label.new()
    native_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    native_label.text="Native Control wrapping uses native minimum notifications and theme metrics."
    grid.add_child(native_label)
    await mount(grid)
    var narrow=native_label.get_combined_minimum_size()
    check(near(native_label.size.y,narrow.y) and near(grid.layout_size.y,narrow.y),"native Label minimum follows actual assigned width via public signals")
    grid.width=290
    await frames()
    var wide=native_label.get_combined_minimum_size()
    check(near(grid.layout_size.y,wide.y) and narrow.y>=wide.y,"native width-affected minimum remeasures without invented height-for-width API")
    await release(grid)
    entry.free()
    await frames()
    check(Hosts.controls.is_empty(),"native Control adapters clean after unmount")
    print("LAYOUT01_NATIVE_CHECKS ",checks," failed=",failed)
    if not failed: print("LAYOUT01_NATIVE_OK")
    quit(1 if failed else 0)
