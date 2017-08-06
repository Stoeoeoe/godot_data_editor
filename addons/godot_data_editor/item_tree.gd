# Item Tree
tool
extends Control

var dummy_root = null


onready var tree = get_node("Panel/VBox/Tree")								# The item tree
onready var class_context_menu = get_node("ClassContextMenu")				# Context menu when right clicking on a class
onready var instance_context_menu = get_node("InstanceContextMenu")			# Context menu when right clicking on an instance
onready var filter_control = get_node("Panel/VBox/Margin/HBoxContainer/Filter")

var item_manager = null 				# Item Manager, used to load, modify and save items

var tree_roots = {}			# Holds a copy of all tree roots, i.e. classes, accessible by class name
var tree_elements = {}		# Reference to all tree elements, accessible by ["_roots"][item_class] (for the roots) and [item_class][id] for the items

signal on_delete_pressed					# Emitted when item is deleted
signal on_rename_pressed					# Emitted when item is renamed
signal on_duplicate_pressed					# Emitted when item is duplicated
signal on_new_item_pressed					# Emitted when new item is created
signal on_open								# Emitted when item is opened in OS
signal on_item_selected(item, is_leaf)		# Emitted when a tree item is selected, carries the item and wheter or not it is a leaf element

var last_selected = null			# Reference to last selected item
var last_selected_id = ""			# Name/id of last selected item
var last_selected_class = ""		# Name/id of last selected class
var collapsed_item_classes = []		# Contains a list of all item classes/tree items which were expanded before reloading

var plugin_config = null

var filter = ""						# Tree filter

# Load the tree when ready	
func _ready():
	tree.set_hide_root(true)
	tree.set_select_mode(Tree.SELECT_SINGLE)
	tree.set_allow_rmb_select(true)
	load_tree()

	
func load_tree(is_reload = false):
	save_collapsed_state()

	plugin_config = ConfigFile.new()
	plugin_config.load("res://addons/godot_data_editor/plugin.cfg")

	self.item_manager = Globals.get("item_manager")
	tree_elements = {}
	tree_roots = {}
	last_selected_id = ""
	last_selected_class = ""
	last_selected = null
	var tree_element_to_be_selected = null

	# Store the class and name of the last selected item, in case the tree is reloaded
	last_selected = tree.get_selected()
	if last_selected:
		if last_selected.has_meta("item"):
			if last_selected.get_meta("item").get("_id"):
				self.last_selected_id = last_selected.get_meta("item")._id
			else:
				self.last_selected_id = null
		self.last_selected_class = last_selected.get_meta("class")

	
	tree.clear()
		
	# Create the roots for each item class, e.g. actors, monsters, crystals...
	dummy_root = tree.create_item()
	tree_elements["_roots"] = {}
	var classes = item_manager.class_names
	for item_class in classes:
		var root = create_item_root(item_class)
		tree_elements["_roots"][item_class] = root
	pass
	
	# Populate the list with items
	classes.sort()
	for item_class in classes:
		tree_elements[item_class] = {}
		if item_manager.invalid_classes.has(item_class):
			continue
		
		var ids = item_manager.items[item_class].keys()
		ids.sort()
		for id in ids:
			var item = item_manager.get_item(item_class, id)
			if filter == "" or id.find(filter) != -1:
				var tree_item = add_leaf(item, false)
		pass
	pass
	
	if last_selected_id:
		tree_element_to_be_selected = get_tree_item(last_selected_class, last_selected_id)
	elif last_selected_class:
		tree_element_to_be_selected = get_tree_item(last_selected_class)
	elif tree.get_root().get_children():	
		tree_element_to_be_selected = tree.get_root().get_children()
	else:
		tree_element_to_be_selected = null			# No elements to be selected
		
		
	# Handle filter
	if tree_element_to_be_selected and not filter_control.has_focus():
		tree.grab_focus()
		tree_element_to_be_selected.select(0)

	# Collapse all class tree items which were previously collapsed
	restore_collapsed_state()

func create_item_root(item_class):
	var tree_item = tree.create_item(dummy_root)
	tree_item.set_selectable(0, true)
	tree_item.set_icon(0, load(plugin_config.get_value("custom", "class_directory") + "/" + item_class + ".png"))
	tree_item.set_text(0, item_class.capitalize())
	tree_item.set_meta("class", item_class)
	tree_roots[item_class] = tree_item
	return tree_item

func select_first_element():
	var first_element = tree.get_root().get_children()
	if first_element:
		first_element.select(0)
		first_element = first_element.get_children()
		last_selected = first_element.get_meta("item")
		last_selected_id = last_selected._id
		last_selected_class = last_selected._class
	return last_selected



# Creates a new tree item, optionally with an existing item
func add_leaf(item, update_order):
	var id = item._id
	var item_class = item._class
	var tree_item = tree.create_item(tree_roots[item_class])
	set_tree_item_label_text(item, tree_item)
	tree_item.set_selectable(0, true)
	tree_item.set_meta("class", item_class)
	tree_item.set_meta("item", item)
	
	tree_elements[item_class][id] = tree_item

	# Don't order the tree in the beginning as the ids will already be sorted
	if update_order:
		# Move the items which come before in the alphabet to the top
		var elements_name_array = tree_elements[item_class].keys()
		elements_name_array.sort()
		tree_item.move_to_top()
		var to_be_reordered = []
		for element_name in elements_name_array:
			if str(id) > str(element_name) or str(id) == str(element_name):
				to_be_reordered.append(element_name)
			else:
				break
		pass
		to_be_reordered.invert()
		for element_name in to_be_reordered:
			tree_elements[item_class][element_name].move_to_top()
 		pass
		tree_item.select(0)
	return tree_item


func set_tree_item_label_text(item, tree_item = null):
	if tree_item == null:
		tree_item = get_tree_item(item._class, item._id)
		
	if item._dirty or not item._persistent:
		tree_item.set_text(0, " " + item._display_name + " (*)")
		tree_item.set_custom_color(0, Color(1, 0.5, 0.5))
	else:
		tree_item.set_text(0, " " + item._display_name)
		tree_item.set_custom_color(0, Color(0.7, 0.7, 0.7))
		
func get_selected_item_root():
	var selected = tree.get_selected()
	if selected.has_meta("item"):
		return selected.get_parent()
	else:
		return selected


# A tree element in the tree was selected (either class or item)
func _on_Tree_cell_selected():
	emit_signal("on_item_selected", get_selected_item(), get_selected_class()) 

func get_selected_item():
	var selected = tree.get_selected()
	if selected.has_meta("item"):
		return selected.get_meta("item")
	else:
		return null
		

func get_selected_class():
	return tree.get_selected().get_meta("class")
		
		
func get_tree_item(item_class, id = ""):
	if id != "":
		if tree_elements.has(item_class) and tree_elements[item_class].has(id):
			return tree_elements[item_class][id]
		else:
			return null
	else:
		if tree_elements["_roots"].has(item_class):
			return tree_elements["_roots"][item_class]
		else:
			return null

# Sets the selection to a specific tree item
func select_item(item):
	if tree_elements.has(item._class) and tree_elements[item._class].has(item._id):
		tree_elements[item._class][item._id].select(0)

# Sets the selection to a specific class
func select_class(item_class):
	if tree_elements["_roots"].has(item_class):
		tree_elements["_roots"][item_class].select(0)

# Updates the filter and reloads the tree. Quite radical.
func _on_Filter_text_changed( text ):
	self.filter = text
	load_tree()
	
# Saves the collapsed tree items
func save_collapsed_state():
	for item_class in tree_roots:
		if tree_roots[item_class].is_collapsed():
			collapsed_item_classes.append(item_class)
		

# Expands the tree items which were not collapsed before
func restore_collapsed_state():
	for item_class in collapsed_item_classes:
		if tree_roots.has(item_class):
			tree_roots[item_class].set_collapsed(true)
	pass
	collapsed_item_classes = []



# Right click context menu on leafs
# 0 = Add | 1 = Rename | 2 = Delete | 3 = Duplicate | 4 = Open
func _on_InstanceContextMenu_item_pressed(index):
	if index == 0:
		emit_signal("on_new_item_pressed")
	elif index == 1:
		emit_signal("on_rename_pressed")
	elif index == 2:
		emit_signal("on_delete_pressed")		
	elif index == 3:
		emit_signal("on_duplicate_pressed")
	elif index == 4:
		emit_signal("on_open")	
		
###########################################################
# CLASS CONTEXT MENU                                      #
###########################################################
func _on_ClassContextMenu_about_to_show():
	class_context_menu.set_item_text(0, tr("Add") + " " + get_selected_class().capitalize())

func _on_InstanceContextMenu_about_to_show():
	pass

# Right click context menu on class branch
# 0 = Add | 1 = Delete Class
func _on_ClassContextMenu_item_pressed(index):
	if index == 0:
		emit_signal("on_new_item_pressed")
	elif index == 1:
		emit_signal("on_delete_pressed")
	elif index == 2:
		emit_signal("on_rename_pressed")



func _on_Tree_item_rmb_selected(pos):
	var is_leaf = get_selected_item() != null
	if is_leaf:
		instance_context_menu.set_pos(get_global_mouse_pos())
		instance_context_menu.popup()
	else:
		class_context_menu.set_pos(get_global_mouse_pos())
		class_context_menu.popup()	
	
			
func _on_DeleteItemDialog_confirmed():
	var selected_item = get_selected_item()
	if selected_item != null:
		item_manager.delete_item(selected_item)
		load_tree()
		




#TODO: Proper memory management?
