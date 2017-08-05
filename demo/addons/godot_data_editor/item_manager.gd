extends Node

# Holds a dictionary of dictionaries with all items (class and then items)
var items = {}

var class_names = []
var classes = {}
var invalid_classes = []

var config_class_directory = ""
var config_output_directory = ""
var config_sanitize_ids = ""
var config_encrypt = ""
var config_password = ""
var config_extension = ""
var config_serializer = ""

signal class_is_invalid(item_class)
signal item_duplication_failed(title, reason)
signal item_insertion_failed(title, reason)
signal class_insertion_failed(title, reason)
signal custom_property_insertion_failed(title, reason)

var property_blacklist = ["_dirty"]

var default_type_values = {
	str(TYPE_STRING): "",									# OK for simple
	str(TYPE_BOOL): false,									# OK
	str(TYPE_COLOR): Color(0,0,0),
	str(TYPE_OBJECT): "res://",
	str(TYPE_IMAGE): "res://",
	str(TYPE_INT): 0,
	str(TYPE_NODE_PATH): @"",
	str(TYPE_REAL): 0.0,
	str(TYPE_RECT2): Rect2(0,0,32,32),
	str(TYPE_VECTOR2): Vector2(0,0),
	str(TYPE_VECTOR3): Vector3(0,0,0),
	str(TYPE_PLANE): Plane(0,0,0,0),
	str(TYPE_QUAT): Quat(0,0,0,0),
	str(TYPE_TRANSFORM): Transform(Vector3(0,0,0),Vector3(0,0,0),Vector3(0,0,0),Vector3(0,0,0))
	}

var type_names = {"STRING":TYPE_STRING, "BOOL":TYPE_BOOL, "COLOR":TYPE_COLOR, "OBJECT":TYPE_OBJECT, "IMAGE":TYPE_IMAGE, "INT":TYPE_INT, "NODE_PATH":TYPE_NODE_PATH, "REAL":TYPE_REAL, "RECT2":TYPE_RECT2, "VECTOR2":TYPE_VECTOR2, "VECTOR3":TYPE_VECTOR3, "PLANE":TYPE_PLANE, "QUAT":TYPE_QUAT, "TRANSFORM":TYPE_TRANSFORM }


func _init():
	load_manager()
	
	
func load_manager():
	store_unsaved_changes()
	initialize_variables()
	load_config()
	load_class_names()
	load_classes()
	set_up_item_folders()
	load_items()
	reload_unsaved_items()
	Globals.set("item_manager", self)

# Try to keep unsaved changes when (re)loading the item_manager
var unsaved_items = []
func store_unsaved_changes():
	for item_class in items:
		for item in items[item_class].values():
			# Check for id to prevent invalid entries from showing up
			if item and item.get("_id") and (item._dirty or not item._persistent):
				unsaved_items.append(item)
	
# Create a duplicate of the unsaved item because this will not mess up changed properties
func reload_unsaved_items():
	for unsaved_item in unsaved_items:
		print(unsaved_item._id)
		duplicate_item(unsaved_item, unsaved_item._id, unsaved_item._display_name, true)
#		new_item._dirty = true

	pass
	unsaved_items = []
		

func initialize_variables():
	items = {}
	class_names = []
	invalid_classes = []
	classes = {}
	
	config_class_directory = ""
	config_output_directory = ""
	config_sanitize_ids = ""
	config_encrypt = ""
	config_password = ""
	config_extension = ""
	config_serializer = ""	

func load_config():
	var config = ConfigFile.new()
	config.load("res://addons/godot_data_editor/plugin.cfg")
	self.config_class_directory = config.get_value("custom", "class_directory")
	self.config_output_directory = config.get_value("custom", "output_directory")
	self.config_sanitize_ids = config.get_value("custom", "sanitize_ids")
	self.config_encrypt = config.get_value("custom", "encrypt")
	self.config_password = config.get_value("custom", "password")
	self.config_serializer = config.get_value("custom", "serializer")
	self.config_extension = config.get_value("custom", "extension")


func load_class_names():
	class_names.clear()
	var directory = Directory.new()
	if directory.open(config_class_directory) == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != ""):
			if file_name.extension() == "gd" and not directory.current_is_dir() and file_name != "data_item.gd" :
				class_names.append(file_name.replace(".gd", ""))
			file_name = directory.get_next()
	class_names.sort()


# Loads the classes from disk
# TODO: Check if there is an issue with the class and display a warning instead of crashing the whole plugin...
func load_classes():
	classes = {}
	for item_class in class_names:
		classes[item_class] = load(config_class_directory + "/" + item_class + ".gd")
		var error = classes[item_class].reload(true)
		if not error == OK or not classes[item_class]:
			emit_signal("class_is_invalid", item_class)
			invalid_classes.append(item_class)			
	pass


# Creates the directories for the items if they do not yet exist
func set_up_item_folders():
	var directory = Directory.new()
	for item_class in classes:
		var path = config_output_directory + "/" + item_class
		if not directory.dir_exists(path):
			directory.make_dir_recursive(path)

func get_item_path(item):
	return config_output_directory + "/" + item._class + "/" + item._id + "." + config_extension

func get_full_path(item):
	return Globals.globalize_path(config_output_directory + "/" + item._class + "/" + item._id + "." + config_extension)
#	return  config_output_directory.replace("res://", "") + "/" + item._class + "/" + item._id + "." + config_extension

func load_items():
	items.clear()
	var directory = Directory.new()
	for item_class in class_names:
		items[item_class] = {}

		if invalid_classes.has(item_class):
			continue

		directory.open(config_output_directory + "/" + item_class )
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != ""):
			if file_name.extension() == config_extension and not directory.current_is_dir() :
				var id = file_name.basename()
				if config_serializer == "json":
					items[item_class][id] = load_json_item(item_class, file_name)
				elif config_serializer == "binary":
					items[item_class][id] = load_binary_item(item_class, file_name)
				else:
					pass
				items[item_class][id].set_name(items[item_class][id]._class + ":" + id)
			file_name = directory.get_next()
		pass
	pass
	
# Loads a single item stored in the binary format
func load_binary_item(item_class, file_name):
	var file = File.new()
	var id = file_name.basename()
	var status = 0
	if not config_encrypt:
		file.open(config_output_directory + "/" + item_class + "/" + file_name, File.READ)
	else:
		file.open_encrypted_with_pass(config_output_directory + "/" + item_class + "/" + file_name, File.READ, config_password)

	var item = classes[item_class].new(id)
	if status == OK:
		# Load all the variables
		while file.get_pos() < file.get_len():
			var property_name = str(file.get_var())

			var value = file.get_var()
			item.set(property_name, value)
		pass

		item._dirty = false
		item._persistent = true
	else:
		pass			# TODO: Handle
	file.close()
	return item
	
# Loads a single item stored in the json format
func load_json_item(item_class, file_name):
	var file = File.new()
	var id = file_name.basename()
	var status = file.open(config_output_directory + "/" + item_class + "/" + file_name, File.READ)
	var item = classes[item_class].new(id)
	if status == OK:
		var text = file.get_as_text()
		var dict = {}
		dict.parse_json(text)

		for property_name in dict:

			
			if property_name == "_custom_properties":
				var value = dict["_custom_properties"]
				item._custom_properties = {}
				for custom_property in value:
					item._custom_properties[custom_property] = []
					var cp_value = value[custom_property][0]
					var cp_type = value[custom_property][1]
					cp_value = parse_value(cp_type, cp_value)
					item._custom_properties[custom_property].append(cp_type)
					item._custom_properties[custom_property].append(cp_value)
			else:
				var value = dict[property_name][0]
				var type = dict[property_name][1]
				value = parse_value(type, value)
				item.set(property_name, value)
		pass	
		item._dirty = false
		item._persistent = true
	else:
		pass			# TODO: Handle
	file.close()
	return item		

# Handles some special cases of JSON deserialization, e.g. Color
func parse_value(type, value):
	if type == TYPE_COLOR:
		value = Color(value)
	elif type == TYPE_PLANE:
		var split = value.replace("(", "").replace(")", "").split(",")
		value = Plane(split[0], split[1], split[2], split[3])
	elif type == TYPE_QUAT:
		var split = value.replace("(", "").replace(")", "").split(",")
		value = Quat(split[0], split[1], split[2], split[3])		
	elif type == TYPE_RECT2:
		var split = value.replace("(", "").replace(")", "").split(",")
		value = Rect2(split[0], split[1], split[2], split[3])		
	elif type == TYPE_TRANSFORM:
		var split = value.replace("(", "").replace(")", "").split(",")
		value = Transform(Vector3(split[0], split[1], split[2]), Vector3(split[3], split[4], split[5]), Vector3(split[6], split[7], split[8]), Vector3(split[9], split[10], split[11]))		
	return value
					
	
# Saves all items
func save_all_items():
	for item_class in items:
		for id in items[item_class]:
			save_item(items[item_class][id])
		pass
	pass

# Stores an item on the disk and updates the "last modified" property
func save_item(item):
	if item:
		item._last_modified= OS.get_unix_time()
		if config_serializer == "json":
			save_json_item(item)
		elif config_serializer == "binary":
			save_binary_item(item)
		else:
			pass

# Saves a single binary item		
func save_binary_item(item):
	var file = File.new()
	var status = 0
	if not config_encrypt:
		status = file.open(get_item_path(item), File.WRITE)
	else:
		status = file.open_encrypted_with_pass(get_item_path(item), File.WRITE, config_password)
	if status == OK:
		for property in item.get_property_list():
			# Serialize each property, even those starting with an underscore because they might be informative to external editors
			var property_name = property["name"]
			var property_usage = property["usage"]
			if property_usage >= PROPERTY_USAGE_SCRIPT_VARIABLE:
				file.store_var(property_name)
				file.store_var(item.get(property_name))
		pass
		item._persistent = true
		item._dirty = false
	else:
		pass			#TODO: Handle
	file.close()

# Saves a single json item
func save_json_item(item):
	var file = File.new()
	var status = 0
	status = file.open(get_item_path(item), File.WRITE)
	var dict = {}
	if status == OK:
		for property in item.get_property_list():
			# Serialize each property			
			var property_name = property["name"].json_escape()
			var property_usage = property["usage"]
			if property_usage >= PROPERTY_USAGE_SCRIPT_VARIABLE and not property_name in property_blacklist:
				var type = typeof(item.get(property_name))
				var value = item.get(property_name)
				
				# Custom properties are handled separately since they are stored as arrays
				if property_name == "_custom_properties":
					dict["_custom_properties"] = {}
					for custom_property in value:
						var type = value[custom_property][0]
						var sanitized_value = sanitize_variant(value[custom_property][1], type)
						dict["_custom_properties"][custom_property] =  [sanitized_value, type]
					pass	
				# Normal properties are simply stored as type-value pairs in an array
				else:
					value = sanitize_variant(value, type)
					dict[property_name] = [value, type]
		pass
		item._persistent = true
		item._dirty = false
	else:
		#TODO: Handle
		pass
	file.store_string(dict.to_json())
	file.close()


func sanitize_variant(value, type):
	if type == TYPE_COLOR:
		value = value.to_html()
	elif type == TYPE_STRING:
		value = value.json_escape()
	return value


# Deletes a single item
func delete_item(item):
	var path = get_item_path(item)
	var directory = Directory.new()
	# TODO: Check why items[item._class].erase(item) doesn't work
	var items_of_class = items[item._class]			
	var status = directory.remove(path)
	load_manager()

		
# Gets all items of a specific class
func get_items(item_class):
	if items.has(item_class):
		return items[item_class]
	else:
		return null
	

# Gets a single item 
func get_item(item_class, id):
	if items.has(item_class) and items[item_class].has(id):
		return items[item_class][id]
	else:
		return null
		

# Creates a new item of a given class, adds it to the items dictionary and returns the newly created item
func create_and_add_new_item(item_class, id, display_name):
	id = sanitize_string(id)
	id = rename_id_if_exists(item_class, id)
	if id == "" or id == null:
		emit_signal("item_insertion_failed", "Item insertion failed", "The item must haven an ID.")
		return null
	if items[item_class].has(id):
		emit_signal("item_insertion_failed", "Item insertion failed", "The item could not be created.")
		return null
	var new_item = classes[item_class].new(id)
	if display_name:
		new_item._display_name = display_name
	items[item_class][id] = new_item
	new_item._created = OS.get_unix_time()
	return new_item

func duplicate_item(item, id, display_name, overwrite = true):
	id = sanitize_string(id)
	if not overwrite:
		id = rename_id_if_exists(item._class, id)
	if id == "" or id == null:
		emit_signal("item_duplication_failed", "Item duplication failed", "The item must haven an ID.")
		return null
	if items[item._class].has(id) and not overwrite:
		emit_signal("item_duplication_failed", "Item duplication failed", "The item could not be duplicated because it already exists.")
		return null
				
	var new_item = classes[item._class].new(id)
	# Copy all properties
	for property in new_item.get_property_list():
		if property["usage"] >= PROPERTY_USAGE_SCRIPT_VARIABLE:
			new_item.set(property["name"], item.get(property["name"]))
	new_item._id = id
	if display_name:
		new_item._display_name = display_name
	else:
		new_item._display_name = new_item._id
	
	new_item._dirty = true
	new_item._persistent = false
	items[new_item._class][new_item._id] = new_item
	items[new_item._class][id].set_name(new_item._class + ":" + id)
	return new_item
	
# Rename the item, delete the old entry, overwrite the id and save anew
# TODO: Could it still be referenced/locked somewhere?
# TODO: Check for duplicate ids?
func rename_item(item, new_id):
	new_id = sanitize_string(new_id)
	var directory = Directory.new()
	directory.remove(get_item_path(item))
	if item._id == item._display_name:
		item._display_name = new_id
	item._id = new_id
	save_item(item)
	load_manager()

# Adds a custom property to an item. 
# Returns true if it succeeded, false if it failed
func add_custom_property(item, name, type):
	name = sanitize_string(name.strip_edges())

	if item.get(name):
		emit_signal("custom_property_insertion_failed", "Custom Property Insertion Failed", "There already is a property with that name.")
		return false		
	if item._custom_properties.has(name):
		emit_signal("custom_property_insertion_failed", "Custom Property Insertion Failed", "There already is a custom property with that name.")
		return false
	elif name == '':
		emit_signal("custom_property_insertion_failed", "Custom Property Insertion Failed", "The custom property name cannot be empty.")
		return false
	else:	
		item._custom_properties[str(name)] = [type, default_type_values[str(type)]]
		item._dirty = true
		return true
	
func delete_custom_property(item, property_name):
	item._custom_properties.erase(property_name)
		
func delete_class(item_class):
	# Delete items
	var directory = Directory.new()
	var path = config_output_directory + "/" + item_class
	var status = directory.open(path)
	if status == OK:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while (file_name != ""):
			if not directory.current_is_dir():
				directory.remove(path + "/" + file_name)
			file_name = directory.get_next()
		pass
	directory.remove(path)
	classes.erase(item_class)
	class_names.erase(item_class)
	items.erase(item_class)
	
	directory.remove(config_class_directory + "/" + item_class + ".gd")
	directory.remove(config_class_directory + "/" + item_class + ".png")

func create_class(name, icon_path):
	# Check if the classes folder already exists. If not, create it-
	var directory = Directory.new()
	if not directory.dir_exists(config_class_directory):
		directory.make_dir(config_class_directory)
	
	name = sanitize_string(name)
	if name == "":
		emit_signal("class_insertion_failed", tr("Invalid name"), tr("The class name cannot be empty."))
		return 
	elif class_names.has(name):
		emit_signal("class_insertion_failed", tr("Invalid name"), tr("The class name already exists."))
		return 
		
	# Handle icons
	var icon_file = File.new()
	if icon_path == "" or not icon_file.file_exists(icon_path):
		icon_path = "res://addons/godot_data_editor/icons/icon_empty.png"
	
	var icon_resource = load(icon_path)
	var icon_data = icon_resource.get_data()
	if icon_data.get_width() <= 22 and icon_data.get_height() <= 22:
		var directory = Directory.new()
		var error = directory.copy(icon_path, config_class_directory + "/" + name + ".png")
		if error != OK:
			emit_signal("class_insertion_failed", tr("Could not copy icon"), tr("There was a problem while copying the icon. Was it already opened by another program?") +  "\nError code: " + str(error))
			return
	else:
		emit_signal("class_insertion_failed", tr("Invalid icon size"), tr("Icon must be smaller than 22x22 pixels."))
		return
		
	# Create class
	var class_source = ""
	class_source += "extends \"res://addons/godot_data_editor/data_item.gd\"\n\n"
	class_source += "export(String) var your_string_property = \"\"\n"
	class_source += "export(bool) var your_boolean_property = true\n"
	class_source += "export(Color) var your_color_property = Color(1,0,1)\n"
	class_source += "\n\n\n"
	class_source += "func _init(id).(id):\n"
	class_source += "\tpass\n"
	
	var script_file = File.new()
	var directory = Directory.new()
	if not directory.dir_exists(config_class_directory):
		directory.make_dir(config_class_directory)
	
	script_file.open(config_class_directory + "/" + name + ".gd", File.WRITE)
	script_file.store_string(class_source)
	script_file.close()
	load_manager()
	
	
func sanitize_string(string):
	if config_sanitize_ids:
		return string.replace(" ", "_").replace("\\", "_").replace("/", "_").replace(":", "_").replace("*", "_").replace("?", "_").replace("\"", "_").replace("<", "_").replace(">", "_").replace("|", "_").to_lower()
	else:
		return string
		
func rename_id_if_exists(item_class, id):
	if not items[item_class].has(id):
		return id
	else:
		var regex = RegEx.new()
		regex.compile("(\\D*)(\\d*)")
		var has_valid_name = false
		var number = 0
		var current_name = id
		while(true):
			regex.find(current_name)
			var id_without_number = regex.get_capture(1)
			var number_at_end_string = regex.get_capture(2)
			var number_at_end = int(number_at_end_string)
			number = number + number_at_end + 1
			var new_id = id_without_number + str(number)
			if not items[item_class].has(new_id):
				return new_id
				

func rename_class(item_class, new_item_class):
	new_item_class = sanitize_string(new_item_class)
	var directory = Directory.new()
	if new_item_class == "":
		emit_signal("class_insertion_failed", tr("Invalid name"), tr("The class name cannot be empty."))
		return 
	elif class_names.has(new_item_class):
		emit_signal("class_insertion_failed", tr("Invalid name"), tr("The class name already exists."))
		return 
	
	directory.rename(config_class_directory + item_class + ".gd", config_class_directory + new_item_class + ".gd")
	directory.rename(config_class_directory + item_class + ".png", config_class_directory + new_item_class + ".png")
	directory.rename(config_output_directory + "/" + item_class, config_output_directory + "/" + new_item_class)
	load_manager()
		
		
func rename_extension_of_all_items(new_extension, serializer):
	var directory = Directory.new() 
	for item_class in class_names:
		for id in items[item_class]:
			var item = items[item_class][id]
			var original_item_path = get_item_path(item)
			var new_item_path = original_item_path.replace("." + config_extension, "." + new_extension)
			if serializer == config_serializer:
				directory.rename(original_item_path, new_item_path)
				directory.remove(original_item_path)
				load_config()
				save_all_items()
			else:
				directory.remove(original_item_path)
				load_config()
				save_all_items()
	pass
	

func delete_and_resave(is_encrypted, password):
	var directory = Directory.new() 
	for item_class in class_names:
		for id in items[item_class]:
			var item = items[item_class][id]
			var item_path = get_item_path(item)
			directory.remove(item_path)
		pass
	pass
	load_config()
	save_all_items()
	
func has_unsaved_items():
	for item_class in items:
		for id in items[item_class]:
			var item = items[item_class][id]
			if item._dirty:
				return true
		pass
	pass
	return false

# TODO: Lazy loading
# TODO: Arrays