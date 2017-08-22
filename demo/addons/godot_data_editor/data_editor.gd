tool
extends EditorPlugin

var data_editor_class = preload("data_editor_gui.tscn")
var data_class = preload("data.gd")
var gui = null

var all_items = {}

signal data_item_class_opened(item_class)
	
func _enter_tree():	
	OS.set_low_processor_usage_mode(true)
	# Currently, adding the singleton automatically, does not work
	#check_for_data_singleton()
	check_plugin_settings()
	gui = data_editor_class.instance()
	get_editor_viewport().add_child(gui)
	gui.set_area_as_parent_rect()
	gui.hide()


# Remove control and data singleton
func _exit_tree():
	OS.set_low_processor_usage_mode(false)
	get_editor_viewport().remove_child(gui)
	if gui:
		gui.free()
	var config = ConfigFile.new()
	#var status = config.load("res://engine.cfg")
	#if status == OK:
	#	if not config.has_section_key("autoload", "data"):
	#		config.set_value("autoload", "data", null)
	#		config.save("res://engine.cfg")
			
		# Check if the Classes and Data folders exist
	Globals.clear("item_manager")
	
func _ready():
	gui.connect("class_edit_requested", self, "edit_class", [])
	Globals.set("debug_is_editor", true)

# Opens the selected class in the Script Editor
func edit_class(item_class):
	edit_resource(item_class)
	
	
# TODO: Maybe there is a way  to refresh the tree without restart?
func check_for_data_singleton():
	pass
	#var config = ConfigFile.new()
	#var status = config.load("res://engine.cfg")
	#if status == OK and not config.has_section_key("autoload", "data"):
	#	config.set_value("autoload", "data", "*res://addons/godot_data_editor/data.gd")
	#	config.save("res://engine.cfg") 
	
# Load the plugin settings and adds default if they do not exist.
# TODO: Obtain defaults from dialog
func check_plugin_settings():
	var config = ConfigFile.new()
	var status = config.load("res://addons/godot_data_editor/plugin.cfg")
	if status == OK:
		if not config.has_section_key("custom", "class_directory"):
			config.set_value("custom", "class_directory", "res://classes")
			# TODO: Create folders	
		if not config.has_section_key("custom", "extension"):
			config.set_value("custom", "extension", "json")
		if not config.has_section_key("custom", "output_directory"):
			config.set_value("custom", "output_directory", "res://data")
			# TODO: Create folders	
		if not config.has_section_key("custom", "password"):
			config.set_value("custom", "password", "")
		if not config.has_section_key("custom", "sanitize_ids"):
			config.set_value("custom", "sanitize_ids", true)
		if not config.has_section_key("custom", "serializer"):
			config.set_value("custom", "serializer", "json")
	config.save("res://addons/godot_data_editor/plugin.cfg")
			

# Virtual: Name of the tool button on top
func get_name():
	return "Data"

# Virtual: Makes sure that the control owns the main screen
func has_main_screen():
	return true

# Virtual: 
func make_visible(visible):
	if gui and visible:
		gui.reload()
		gui.show()
	elif gui:
		gui.hide()
		 

