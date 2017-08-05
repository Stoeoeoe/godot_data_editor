tool
extends ConfirmationDialog

#var text = ""
#var title = ""
var placeholder_1 = ""
var placeholder_2 = ""
var caller = null
var callback_method = ""

onready var line_edit_1 = get_node("VBox/LineEdit1")
onready var line_edit_2 = get_node("VBox/LineEdit2")


#func _init(text, placerholder_1 = "", placeholder_2 = ""):

func popup(caller, callback_method, title, text, placeholder_1 = "", default_text_1 = "", placeholder_2 = "", default_text_2 = ""):
	self.caller = caller
	self.callback_method = callback_method
	self.placeholder_1 = placeholder_1
	self.placeholder_2 = placeholder_2
	
	if not caller.is_connected("input_dialog_confirmed", caller, callback_method):
		caller.connect("input_dialog_confirmed", caller, callback_method, [])
	set_text(text)
	set_title(title)
	if placeholder_1 == "":
		line_edit_1.hide()
	else:
		line_edit_1.show()
		line_edit_1.set_placeholder(placeholder_1)

		
	if placeholder_2 == "":
		line_edit_2.hide()
	else:
		line_edit_2.show()
		line_edit_2.set_placeholder(placeholder_2)

	line_edit_1.set_text(default_text_1)
	line_edit_2.set_text(default_text_2)
	self.popup_centered()
	
	if not line_edit_1.is_hidden():
		line_edit_1.grab_focus()

func _on_ConfirmationDialog_confirmed():
	var text1 = line_edit_1.get_text().strip_edges()
	var text2 = line_edit_2.get_text().strip_edges()
	if placeholder_2:
		caller.emit_signal("input_dialog_confirmed", text1, text2)
	elif placeholder_1:
		caller.emit_signal("input_dialog_confirmed", text1)
	else:
		caller.emit_signal("input_dialog_confirmed")		
		
		
	caller.disconnect("input_dialog_confirmed", caller, callback_method)