extends Node

var _items_path = ""

# Class information
# No setter, that's why there is a comma
var _class setget ,get_class
var _class_name setget ,get_class_name

var _dirty = false							# TODO: Exclude
var _persistent = false						# TODO: Exclude


var _id = ""
var _display_name setget set_display_name,get_display_name
var _created = 0
var _last_modified = 0


# Instance-level custom properties, consists of arrays containing name, type, (hint and hint_text), default value
var _custom_properties = {}

func _ready():
	var config = ConfigFile.new()
	config.load("res://addons/DataEditor/plugin.cfg")
	_items_path = config.has_section_key("plugin", "output_directory")

func get_class():
	return self.get_script().get_path().get_file().basename()

func get_class_name():
	return self.get_class().capitalize()
	
	
func get_display_name():
	if _display_name == null or _display_name == "":
		return self._id
	else:
		return _display_name
		
func set_display_name(name):
	_display_name = name


func sanitize_value(property, type, value):
	if property["type"] == TYPE_COLOR:
		value = value.to_html()
	elif property["type"] == TYPE_STRING:
		value = value.json_escape()
	return value
		
		
		
func _init(id):
	self._id = id
	
func _notification(what):
	print(what)