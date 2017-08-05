tool
extends Panel
# This class represents an item control used to change the data values, e.g. the text boxes.


var load_icon = preload("icons/icon_load.png")
var multi_line_icon = preload("icons/icon_multi_line.png")

var property_name = ""
var type = TYPE_NIL
var hint = 0
var hint_array = [] 
var hint_text = ""
var number_of_hints = 0
var value = null				# The value of the property

var has_delete_button = false


var control = null
var popup = null
var menu = null
var value_editor = []


var dialog = null
var object_type_line_edit = null


signal on_property_value_changed(property, value)
signal property_item_load_button_down(property_item)
signal custom_property_delete_requested(property_name)

# has_delete is used for custom properties
func initialize(property_name, type, value = null,  hint = 0, hint_text = "", has_delete = false):
	self.property_name = property_name
	self.type = type
	self.value = value
	self.hint = hint
	self.hint_text = hint_text
	self.has_delete_button = has_delete
		


func _ready():	
	# Label describing property
	var property_label = Label.new()
	property_label.set_text(property_name.capitalize())

	# Split property hints
	self.hint_array = hint_text.split(",")
	self.number_of_hints = hint_array.size()
	
	##################################################
	# For each type, one control is defined
	##################################################
	if type == TYPE_BOOL:
		create_bool()
	elif type == TYPE_INT or type == TYPE_REAL:
		create_number()
	elif type == TYPE_STRING:
		create_string()
	elif type == TYPE_COLOR:
		create_color()
	elif type == TYPE_NODE_PATH:
		create_node_path()
	elif type == TYPE_VECTOR2:
		control = create_custom_editor_button(value);
		create_custom_editor(2, 2, 10, ["x", "y"])
	elif type == TYPE_VECTOR3:
		control = create_custom_editor_button(value);
		create_custom_editor(3, 3, 10, ["x", "y", "z"])
	elif type == TYPE_RECT2:
		control = create_custom_editor_button(value);
		create_custom_editor(4, 4, 10, ["x", "y", "w", "h"])
	elif type == TYPE_PLANE:
		control = create_custom_editor_button(value);
		create_custom_editor(4, 4, 10, ["x", "y", "z", "d"])
	elif type == TYPE_QUAT:
		control = create_custom_editor_button(value);
		create_custom_editor(4, 4, 10, ["x", "y", "z", "w"])
	elif type == TYPE_TRANSFORM:
		control = create_custom_editor_button(value);
		create_custom_editor(12, 4, 16, ["xx", "xy", "xz", "xo", "yx", "yy", "yz", "yo", "zx", "zy", "zz", "zo"])
	elif type == TYPE_OBJECT or type == TYPE_IMAGE:
		create_object_or_image()
	else:
		control = get_not_yet_supported()
			
	control.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	control.set_margin(MARGIN_LEFT, 200)
	control.set_custom_minimum_size(Vector2(get_parent().get_parent().get_parent().get_size().x - 270, 0))
	add_child(property_label)
	add_child(control)
	
	if has_delete_button:
		var delete_button = ToolButton.new()
		delete_button.set_button_icon(preload("res://addons/godot_data_editor/icons/icon_remove.png"))
		delete_button.set_h_size_flags(Control.SIZE_EXPAND)
		delete_button.set_margin(MARGIN_LEFT, get_parent().get_parent().get_parent().get_size().x - 34 )
		delete_button.set_custom_minimum_size(Vector2(28, 24))
		delete_button.connect("button_down", self, "route_delete_request")
#		delete_button.connect("button_down", self, "emit_signal", ["custom_property_delete_requested")
		add_child(delete_button)

func route_delete_request():
	emit_signal("custom_property_delete_requested")

func create_custom_editor_button(value):
	var button = Button.new()
	button.set_text(str(value))
	button.connect("button_down", self, "open_custom_editor")
	return button
	
func open_custom_editor():
	menu.set_pos(get_global_mouse_pos())
	menu.get_children()[1].grab_focus()
	menu.popup()


##################################################
# All types
##################################################

func create_bool():
	control = CheckBox.new()
	control.set_text(str(value))
	control.set_pressed(value)
	control.connect("toggled", self, "set_checkbox_label", [])
	control.connect("toggled", self, "property_value_changed", [])

func create_number():
	if hint == PROPERTY_HINT_RANGE:
		var control_min = -16777216
		var control_max = 16777216

		var control_step = 0
		if type == TYPE_INT:
			control_step = 1
		else:
			control_step = 0.00001

		if number_of_hints >= 1:
			if not hint_array[0].empty():
				control_min = int(hint_array[0])
					
		if number_of_hints >= 2:
			if not hint_array[1].empty():
				control_max = int(hint_array[1])
			
		if number_of_hints >= 3:
			if not hint_array[2].empty():
				control_step = float(hint_array[2])
		
		# TODO: This does not seem to be exposed in GDScript yet?	
		if number_of_hints >= 4 and hint_array[3] == "slider":
			control = HSlider.new()
			control.set_min(control_min)
			control.set_max(control_max)
			control.set_step(control_step)
			control.set_value(value);
			control.connect("value_changed", self, "property_value_changed", [])
			#controlset_size(Size2(110,30)*EDSCALE);
		else:
			control = SpinBox.new()
			control.set_min(control_min)
			control.set_max(control_max)
			control.set_step(control_step) 
			control.set_value(value)
			control.connect("value_changed", self, "property_value_changed", [])
			#set_size(Size2(70,35)*EDSCALE);
	elif hint == PROPERTY_HINT_ENUM:
		control = MenuButton.new()
		for i in range(0, hint_array.size()):
			control.get_popup().add_item(hint_array[i])
		control.set_flat(false)
#			control.set_pos(get_pos())
		control.set_text(control.get_popup().get_item_text(value))
		control.get_popup().connect("item_pressed", self, "int_enum_property_value_changed", [])

	elif hint == PROPERTY_HINT_EXP_EASING:
		control = get_not_yet_supported()
	elif hint == PROPERTY_HINT_FLAGS:
		control = get_not_yet_supported()
	else:
		control = SpinBox.new()
		control.set_value(value);
		if type == TYPE_REAL:
			control.set_min(-16777216)
			control.set_max(16777216)
			control.set_step(0.00001)
		else:
			control.set_max(2147483647)
			control.set_min(-2147483647)
			control.set_step(1)
		control.connect("value_changed", self, "property_value_changed", [])
		#control = create_custom_editor_button(value);
		#create_custom_editor(1, 1, 50, ["value"])
		#custom_editor_value_applied()

func create_string():
	if hint == PROPERTY_HINT_ENUM:
		control = MenuButton.new()
		for i in range(0, hint_array.size()):
			control.get_popup().add_item(hint_array[i])
		control.set_flat(false)
		control.set_text(str(value))
		control.get_popup().connect("item_pressed", self, "string_enum_property_value_changed", [])
	elif hint == PROPERTY_HINT_MULTILINE_TEXT:
		# RABRABRAB
		control = HBoxContainer.new()
		var line_edit = LineEdit.new()
		line_edit.set_h_size_flags(SIZE_EXPAND_FILL)
		var more_button = ToolButton.new()
		more_button.set_button_icon(multi_line_icon)
		line_edit.set_text(str(value))
		control.add_child(line_edit)
		control.add_child(more_button)

		popup = Popup.new()
		popup.set_size(Vector2(600, 400))
		var text_edit = TextEdit.new()
		text_edit.set_anchor_and_margin(MARGIN_LEFT, ANCHOR_BEGIN, 0)
		text_edit.set_anchor_and_margin(MARGIN_TOP, ANCHOR_BEGIN, 0)
		text_edit.set_anchor_and_margin(MARGIN_RIGHT, ANCHOR_END, 0)
		text_edit.set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, 0)
		add_child(popup)
		popup.add_child(text_edit)
		text_edit.set_text(str(value))

		line_edit.connect("text_changed", self, "property_value_changed", [])
		more_button.connect("button_down", popup, "popup_centered_minsize", [Vector2(800, 600)])
		popup.connect("popup_hide", self, "text_edit_popup_closed", [])
	else:
		control = LineEdit.new()
		control.set_text(str(value))
		control.connect("text_changed", self, "property_value_changed", [])

func create_color():
	control = ColorPickerButton.new()
	# If, for some reason, the color is still (de)serialized wrongly, split the string
	if typeof(value) == TYPE_STRING and value.find(","):
		var split_color = value.split(",")
		value = Color(split_color[0], split_color[1], split_color[2], split_color[3])
	control.set_color(value)
	control.connect("color_changed", self, "property_value_changed", [])

func create_node_path():
	control = LineEdit.new()
	control.set_text(value)
	control.connect("text_changed", self, "property_value_changed", [])


# Adapted Port of property editor 
func create_custom_editor(amount, columns, label_w, strings, read_only = false):
	self.value_editor = []
	self.menu = PopupMenu.new()
	menu.connect("popup_hide", self, "custom_editor_value_applied")
	var w = 80
	var h = 20
	var m = 10
	var MAX_VALUE_EDITORS = 12
	var value_label = [] 
	for i in range(0, amount):
		var line_edit = LineEdit.new()
		line_edit.set_text(str(get_custom_editor_value(i)))
		value_editor.append(line_edit)
		menu.add_child(value_editor[i])	
		value_label.append(Label.new())
		menu.add_child(value_label[i])	
	pass
	
	var rows=((amount-1)/columns)+1
	menu.set_size(Vector2( m*(1+columns)+(w+label_w)*columns, m*(1+rows)+h*rows ) );
	for i in range(0, amount):
		var c = i % columns;
		var r = i / columns;
		value_editor[i].show()
		value_label[i].show()
		if i < strings.size():
			value_label[i].set_text(strings[i])
		else:
			value_label[i].set_text("")
			
		value_editor[i].set_pos( Vector2( m+label_w+c*(w+m+label_w), m+r*(h+m) ))
		value_editor[i].set_size( Vector2( w, h ) )
		value_label[i].set_pos( Vector2( m+c*(w+m+label_w), m+r*(h+m) ) )
		value_editor[i].set_editable(!read_only)

	pass
	
	add_child(menu)
	

func custom_editor_value_applied():
	# TODO: Validate 
	var va = []
	for line in value_editor:
		var v = float(line.get_text())
		va.append(v)
	
	var value = null
	if type == TYPE_VECTOR2:
		value = Vector2(va[0], va[1])
	if type == TYPE_VECTOR3:
		value = Vector3(va[0], va[1], va[2])	
	if type == TYPE_RECT2:
		value = Rect2(va[0], va[1], va[2], va[3])	
	if type == TYPE_PLANE:
		value = Plane(va[0], va[1], va[2], va[3])	
	if type == TYPE_QUAT:
		value = Quat(va[0], va[1], va[2], va[3])
	if type == TYPE_TRANSFORM:
		value = Transform(Vector3(va[0], va[1], va[2]), Vector3(va[4], va[5], va[6]), Vector3(va[8], va[9], va[10]), Vector3(va[3], va[7], va[11]))
	
	if value != self.value:
		self.value = value
		emit_signal("on_property_value_changed", property_name, value)
		control.set_text(str(value))
	
func get_custom_editor_value(index):
	if type == TYPE_VECTOR2:
		if index == 0: return value.x
		else: return value.y
	elif type == TYPE_VECTOR3:
		if index == 0: return value.x
		elif index == 1: return value.y
		else: return value.z
	elif type == TYPE_RECT2:
		if index == 0: return value.pos.x
		elif index == 1: return value.pos.y
		elif index == 2: return value.size.x
		else: return value.size.y
	elif type == TYPE_QUAT:
		if index == 0: return value.x
		elif index == 1: return value.y
		elif index == 2: return value.z
		else: return value.w	
	elif type == TYPE_PLANE:
		if index == 0: return value.x
		elif index == 1: return value.y
		elif index == 2: return value.z
		else: return value.d
	elif type == TYPE_TRANSFORM:
		if index == 0: return value.basis.x.x
		elif index == 1: return value.basis.x.y
		elif index == 2: return value.basis.x.z
		elif index == 3: return value.origin.x
		elif index == 4: return value.basis.y.x
		elif index == 5: return value.basis.y.y
		elif index == 6: return value.basis.y.z
		elif index == 7: return value.origin.y
		elif index == 8: return value.basis.z.x
		elif index == 9: return value.basis.z.y
		elif index == 10: return value.basis.z.z
		else: return value.origin.z
	
func create_object_or_image():
	value = str(value)
	control = HBoxContainer.new()
	object_type_line_edit = LineEdit.new()
	object_type_line_edit.set_text(str(value))
	object_type_line_edit.set_h_size_flags(SIZE_EXPAND_FILL)
	object_type_line_edit.connect("text_changed", self, "property_value_changed", [])
	if hint_text == "Texture" or type == TYPE_IMAGE:
		var f = File.new()
		if value != null and f.file_exists(value):
			var texture = load(value)
			var texture_frame = TextureFrame.new()
			texture_frame.set_expand(true)
			texture_frame.set_custom_minimum_size(Vector2(get_parent_area_size().y, get_parent_area_size().y))
			texture_frame.set_texture(texture)
			var texture_popup = Popup.new()
			var texture_frame_full = TextureFrame.new()
			texture_frame_full.set_texture(texture)
			texture_popup.add_child(texture_frame_full)
			texture_popup.set_size(texture.get_size())
#					texture_frame.set_process_input(true)
#					texture_frame.connect("input_event", self, "open_image", [])
			control.add_child(texture_frame)
#					control.add_child(texture_popup)

	control.add_child(object_type_line_edit)
	
	
	var load_button = ToolButton.new()
	load_button.set_button_icon(load_icon)
	control.add_child(load_button)
	
	
	if 	Globals.get("debug_is_editor"):		
		dialog = EditorFileDialog.new()
		dialog.set_access(EditorFileDialog.ACCESS_RESOURCES)
		dialog.set_mode(EditorFileDialog.MODE_OPEN_FILE)
		load_button.connect("button_down", dialog, "popup_centered_ratio")

		var filter = ""
		var resource_type = ""
		var extension_array = [] 
		
		if hint == PROPERTY_HINT_RESOURCE_TYPE:
			resource_type = hint_text
			extension_array = ResourceLoader.get_recognized_extensions_for_type(resource_type)
		else:
			extension_array = hint_array

		for extension in extension_array:
#				if filter.begins_with("."):
#					filter = "*" + extension
#				elif filter.begins_with("*"):
#					filter = "*." + extension
#				filter = filter + " ; " + extension.to_upper()
			extension.replace("*", "").replace(".", "")
			filter =  "*." + extension + " ; " + extension.to_upper()
			dialog.add_filter(filter)
		pass 
		dialog.connect("file_selected", self, "fill_resource_name", [])
		add_child(dialog)

	
	#.add_icon_item(get_icon("Load","EditorIcons"), "Load")



func get_not_yet_supported():
	var control = Label.new()
	control.set_text(str("This type is not yet supported."))
	return control

# TODO: That's all a bit too confusing...
func fill_resource_name(resource_path):
	object_type_line_edit.set_text(resource_path)
	property_value_changed(resource_path)
	if hint_text == "Texture":
		var texture = load(resource_path)
		if texture:
			control.get_child(0).set_texture(texture)

# Sets the label of the checkboxe's text to the value
func set_checkbox_label(value):
	control.set_text(str(value))
	
func property_value_changed(value):
	if type == TYPE_INT:
		value = int(value)
	if type == TYPE_REAL:
		value = float(value)
	if type == TYPE_COLOR:
		value = Color(value)
	if self.value != value:
		self.value = value
		emit_signal("on_property_value_changed", property_name, value)	


func text_edit_popup_closed():
	var text_edit = popup.get_child(0)
	var value = text_edit.get_text()
	if value and self.value != value:
		self.value = value
		emit_signal("on_property_value_changed", property_name, value)
		control.get_child(0).set_text(value)
	
	
	
func int_enum_property_value_changed(value):
	control.set_text(control.get_popup().get_item_text(value))
	if self.value != value:
		self.value = value
		emit_signal("on_property_value_changed", property_name, value)	

# Simply changes the text of the calling menu to the selected value if it's an enum 
func string_enum_property_value_changed(value):
	control.set_text(control.get_popup().get_item_text(value))
	if str(self.value) != str(value):
		self.value = value
		emit_signal("on_property_value_changed", property_name, control.get_popup().get_item_text(value))
		

func open_image(texture):
	pass