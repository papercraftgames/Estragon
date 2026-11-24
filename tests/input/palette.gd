extends SceneTree
const Entry = preload("res://addons/estragon/runtime/node/estragon_2d.gd")
const Box = preload("res://addons/estragon/runtime/node/box.gd")
const Field = preload("res://addons/estragon/runtime/node/input.gd")
const UiButton = preload("res://addons/estragon/runtime/node/button.gd")
var checks := 0
var failed := false
func check(value: bool,label: String):
	checks += 1
	failed = failed or not value
	print("UI04_PALETTE ",label,": ",value)
func frames():
	for i in range(8): await process_frame
func click(node: Node2D):
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = node.get_global_transform_with_canvas()*Vector2(12,12)
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		Input.parse_input_event(event)
		await frames()
func _initialize(): run.call_deferred()
func run():
	root.size = Vector2i(640,460)
	var neutral := Color("#383838")
	var entry := Entry.new()
	entry.width = 620;entry.height = 440;entry.padding = 20;entry.direction = "column";entry.gap = 12
	entry.background_color = Color("#181818")
	var row := Box.new();row.gap = 20
	var input := Field.new();input.value = "Unstyled Input";input.width = 250
	var button := UiButton.new();button.text = "Unstyled Button";button.width = 250
	row.add_child(input);row.add_child(button);entry.add_child(row)
	var readonly := Field.new();readonly.read_only = true;readonly.value = "Read-only value";entry.add_child(readonly)
	var invalid := Field.new();invalid.invalid = true;invalid.placeholder = "Required / invalid";entry.add_child(invalid)
	var disabled := Field.new();disabled.disabled = true;disabled.value = "Disabled value";entry.add_child(disabled)
	var authored := Field.new();authored.background_color = Color("#714626");authored.value = "Explicit background";entry.add_child(authored)
	check(input.background_color==neutral and input._visual_style.colors.background_color==neutral,"constructor getter and cached color neutral")
	check(input.padding==8.0 and input.corner_radius==0 and input.border_width==0,"existing square padding/border retained")
	root.add_child(entry);await frames()
	input.release_focus();await frames();await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var a: Vector2 = input.get_global_transform_with_canvas()*Vector2(input.layout_size.x-5,input.layout_size.y*0.5)
	var b: Vector2 = button.get_global_transform_with_canvas()*Vector2(button.layout_size.x-5,button.layout_size.y*0.5)
	check(picture.get_pixelv(Vector2i(a)).is_equal_approx(neutral) and picture.get_pixelv(Vector2i(b)).is_equal_approx(neutral),"actual unfocused Input and imported Button pixels match383838")
	var prefix := "before" if OS.get_environment("UI04_BASELINE")=="1" else "after"
	picture.save_png("res://input-palette-"+prefix+".png")
	check(input.background_color==neutral and input._visual_style.colors.background_color==neutral,"entering tree retains neutral cache")
	check(authored.background_color==Color("#714626") and authored._visual_style.colors.background_color==Color("#714626"),"explicit background remains authored")
	await click(input)
	check(input.has_focus() and input.focus_color==Color("#9cdcff") and input.background_color==neutral,"pointer focus preserves shared semantic outline and normal surface")
	var edits: Array = []
	input.value_changed.connect(func(a,b): edits.append([a,b]))
	var key := InputEventKey.new();key.keycode = KEY_END;key.pressed = true
	Input.parse_input_event(key);await frames()
	key = InputEventKey.new();key.keycode = KEY_X;key.unicode = 120;key.pressed = true
	Input.parse_input_event(key);await frames()
	check(input.value=="Unstyled Inputx" and edits.size()==1,"native editing and one change notification unaffected")
	var editor: LineEdit = input.get_focus_control()
	editor.select(0,8)
	check(editor.has_selection() and editor.caret_column>0,"native caret/selection retained")
	check(readonly.get_focus_control().editable==false and disabled.get_focus_control().editable==false and not disabled.has_focus(),"read-only and disabled native states retained")
	check(invalid.invalid_color==Color("#f17b83") and invalid.background_color==neutral and disabled.background_color==neutral,"invalid outline and neutral semantic-state host surfaces retained")
	authored.background_color = Color("#254628")
	check(authored._visual_style.colors.background_color==Color("#254628"),"independent explicit override updates cached paint")
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://input-palette-states-"+prefix+".png")
	entry.remove_child(row);entry.add_child(row);await frames()
	check(input.background_color==neutral and input._visual_style.colors.background_color==neutral and input.get_child_count(true)==1,"exit/reenter keeps neutral default and one native endpoint")
	entry.free();await frames()
	print("UI04_PALETTE_ASSERTIONS ",checks," failed=",failed)
	if not failed: print("UI04_PALETTE_OK")
	quit(1 if failed else 0)
