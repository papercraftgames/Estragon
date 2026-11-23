extends SceneTree
const Formatter=preload("res://addons/estragon/editor/formatter.gd")
const Edit=preload("res://addons/estragon/editor/format_edit.gd")
var checks:=0
var errors:=0
func check(value: bool,label: String):
	checks+=1
	print("EDIT01_BUFFER ",label,": ",value)
	if not value: errors+=1
func frames():
	for i in range(8): await process_frame
func _initialize(): run.call_deferred()
func run():
	var code:=CodeEdit.new()
	root.add_child(code)
	code.size=Vector2(300,120)
	code.indent_use_spaces=true
	code.indent_size=4
	var saved='func view():\n    return <Box>\n<Text text="'+"x".repeat(240)+'" />\n</Box>\n'
	for i in range(30): saved+='# padding '+str(i)+'\n'
	code.text=saved
	code.clear_undo_history()
	code.tag_saved_version()
	code.set_caret_line(code.get_line_count()-1)
	code.begin_complex_operation()
	code.insert_text_at_caret("# unsaved user change\n",0)
	code.end_complex_operation()
	var before:=code.text
	code.set_caret_line(2,false)
	code.set_caret_column(12,false)
	code.select(3,6,2,12)
	code.add_caret(1,10)
	await frames()
	code.scroll_vertical=10.5
	code.scroll_horizontal=80
	var vertical:=code.scroll_vertical
	var horizontal:=code.scroll_horizontal
	var report=Formatter.new().format_source(code.text,"buffer",code.indent_use_spaces,code.indent_size)
	check(Edit.apply(code,report),"native edit applies")
	await frames()
	check(code.text==report.text and code.text.contains("# unsaved user change"),"current unsaved text is formatted")
	check(code.get_caret_count()==2 and code.get_caret_line()==2 and code.get_caret_column()==20 and code.get_caret_line(1)==1 and code.get_caret_column(1)==10,"primary/secondary carets follow their source text")
	check(code.has_selection() and code.get_selection_from_line()==2 and code.get_selection_from_column()==20 and code.get_selection_to_line()==3 and code.get_selection_to_column()==10,"reverse selection boundaries follow indentation edits")
	check(code.scroll_vertical==vertical and code.scroll_horizontal==horizontal,"vertical/fractional and horizontal scroll preserved")
	check(code.get_version()!=code.get_saved_version(),"unsaved buffer stays dirty")
	var version:=code.get_version()
	var again=Formatter.new().format_source(code.text,"buffer",true,4)
	check(again.edits.is_empty() and Edit.apply(code,again) and code.get_version()==version,"second format has no native undo/version mutation")
	code.undo()
	check(code.text==before,"one native Undo restores unformatted unsaved buffer")
	code.undo()
	check(code.text==saved,"previous user edit remains a separate undo step")
	code.redo()
	code.redo()
	check(code.text==report.text,"native redo restores formatting")
	code.text=saved
	code.clear_undo_history()
	code.tag_saved_version()
	var clean=Formatter.new().format_source(saved,"buffer",true,4)
	Edit.apply(code,clean)
	check(code.get_version()!=code.get_saved_version(),"formatting a clean unformatted source becomes dirty")
	code.undo()
	check(code.text==saved and code.get_version()==code.get_saved_version(),"undo returns to original saved native version")
	var invalid='func view():\n    return <Box>\n'
	code.text=invalid
	code.clear_undo_history()
	code.tag_saved_version()
	version=code.get_version()
	check(not Edit.apply(code,Formatter.new().format_source(invalid)) and code.text==invalid and code.get_version()==version,"malformed input does not edit or dirty native buffer")
	code.free()
	print("EDIT01_BUFFER_ASSERTIONS ",checks," errors=",errors)
	if errors==0: print("EDIT01_BUFFER_OK")
	quit(0 if errors==0 else 1)
