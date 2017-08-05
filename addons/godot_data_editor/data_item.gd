extends Node

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
	pass
	
	
		
func get_class():
	if _class:
		return _class
	else:
		_class = self.get_script().get_path().get_file().basename()
		return _class


func get_class_name():
	return self.get_class().capitalize()
	
	
func get_display_name():
	if _display_name == null or _display_name == "":
		return self._id
	else:
		return _display_name
		
		
func set_display_name(name):
	_display_name = name


func update_property(property, value):
	var data_singleton = Globals.get_singleton("data")
	if data_singleton:
		data_singleton.set_progress(_class, _id, property, value)

				
func _init(id):
	self._id = id
