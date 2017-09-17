tool
extends Control 

var selected_item = null
var selected_id = null
var selected_class = null


onready var item_tree = get_node("VBox/Body/ItemTree")
onready var id_label = get_node("VBox/Body/Content/VBox/Container/ItemIdLabel")

onready var instance_details = get_node("VBox/Body/Content/VBox/InstanceDetails/")
onready var class_properties = get_node("VBox/Body/Content/VBox/InstanceDetails/HBox/ClassProperties")
onready var custom_properties = get_node("VBox/Body/Content/VBox/InstanceDetails/HBox/CustomProperties")
onready var class_overview = get_node("VBox/Body/Content/VBox/ClassOverview")
onready var no_classes = get_node("VBox/Body/Content/VBox/NoClasses")
 
#onready var last_modified_date = get_node("VBox/Body/Content/VBox/Container/GridContainer/LastModifiedDate")
#onready var created_date = get_node("VBox/Body/Content/VBox/Container/GridContainer/CreatedDate")


onready var new_custom_property_dialog = get_node("NewCustomPropertyDialog")
onready var new_custom_property_name = get_node("NewCustomPropertyDialog/LineEdit")
onready var new_custom_property_type_options = get_node("NewCustomPropertyDialog/TypeOptions")

onready var add_button = get_node("VBox/Head/Add")
onready var delete_button = get_node("VBox/Head/Delete")
onready var duplicate_button = get_node("VBox/Head/Duplicate")
onready var change_display_name_button = get_node("VBox/Body/Content/VBox/Container/HBox/DisplayName")
onready var rename_button = get_node("VBox/Head/Rename")
onready var save_button = get_node("VBox/Head/Save")
onready var save_all_button = get_node("VBox/Head/SaveAll")

onready var copy_id_button = get_node("VBox/Body/Content/VBox/Container/HBox/CopyId")
onready var edit_class_button = get_node("VBox/Body/Content/VBox/Container/HBox/EditClass")
onready var copy_get_item_button = get_node("VBox/Body/Content/VBox/Container/HBox/CopyGetItem")

# Dialogs
onready var input_dialog = get_node("InputDialog")

onready var new_item_class_dialog = get_node("NewClassDialog")
onready var new_item_class_name = get_node("NewClassDialog/ClassName")
onready var new_item_class_icon = get_node("NewClassDialog/ClassIconPath")
onready var new_item_class_icon_dialog = get_node("NewClassDialog/ClassIconFileDialog")


onready var warn_dialog = get_node("WarnDialog")
onready var options_screen = get_node("OptionsDialog")

var item_tree_class = preload("item_tree.tscn")
#var active_element = null
var item_manager = null

signal class_edit_requested(script)
signal input_dialog_confirmed(text1, text2)

# First initialize the item manager which is used for loading, saving and configs
func _init():
	item_manager = preload("item_manager.gd").new()			# This item_manager will add itself to the globals

func _ready():	
	Globals.set("debug_is_editor", false)

	
	# Tree signals
	item_tree.connect("on_new_item_pressed", self, "handle_actions", ["add"])
	item_tree.connect("on_rename_pressed", self, "handle_actions", ["rename"])
	item_tree.connect("on_delete_pressed", self, "handle_actions", ["delete"])
	item_tree.connect("on_duplicate_pressed", self, "handle_actions", ["duplicate"])
	item_tree.connect("on_item_selected", self, "change_item_context", [])
	item_tree.connect("on_open", self, "open_item", [])
		
	custom_properties.connect("custom_property_add_requested", self, "handle_actions", ["add_custom_property"])
	custom_properties.connect("new_custom_property_created", self, "handle_actions", ["add_custom_property"])
	custom_properties.connect("custom_property_delete_requested", self, "delete_custom_property", [])
	class_properties.connect("on_item_changed", self, "toggle_item_dirty_state", [])
	
	options_screen.connect("extension_changed", item_manager, "rename_extension_of_all_items", [])
	options_screen.connect("encryption_changed", item_manager, "delete_and_resave", [])
	
	item_manager.connect("class_insertion_failed", self, "show_warning", [])
	item_manager.connect("item_insertion_failed", self, "show_warning", [])
	item_manager.connect("custom_property_insertion_failed", self, "show_warning", [])
	item_manager.connect("item_duplication_failed", self, "show_warning", [])
#	item_manager.connect("class_is_invalid", self, "show_warning", [])	
	
	# Add types to the custom property type dropdown
	var type_names = item_manager.type_names.keys()
	type_names.sort()
	new_custom_property_type_options.clear()
	var index = 0
	for type in type_names:
		new_custom_property_type_options.add_item(type)
		new_custom_property_type_options.set_item_metadata(index, item_manager.type_names[type])
		index += 1

	# No classes available
	var has_no_classes = item_manager.classes.size() == 0
	if has_no_classes:
		change_display_name_button.set_disabled(has_no_classes)		
		duplicate_button.set_disabled(true)
		save_button.set_disabled(true)
		save_all_button.set_disabled(true)
		save_all_button.set_disabled(true)
		rename_button.set_disabled(true)
		add_button.set_disabled(true)
		delete_button.set_disabled(true)
		copy_id_button.set_disabled(true)
		edit_class_button.set_disabled(true)
		copy_get_item_button.set_disabled(true)
		no_classes.show()
		id_label.set_text("No Classes")
		instance_details.hide()
		class_overview.hide()
	else:
		# Select the first item in the tree when loading the GUI
		var all_classes = item_manager.classes.keys()
		all_classes.sort()
		selected_class = all_classes[0]
		change_item_context(selected_item, selected_class)

# TODO: Implement
func open_item():
	var item_path = item_manager.get_full_path(selected_item)
	var program = ""
	var os_name = OS.get_name()
	if os_name == "Windows":
		program = "explorer"
		item_path = item_path.replace("/", "\\")		# ~_~... 
	# TODO: Not sure if these work... Probably add the possibility to add a custom editor
	elif os_name == "OSX":
		program = "open"								
	else:
		program = "nautilus"
	OS.execute(program, [item_path], false)

func change_item_context(selected_item, selected_class):	
	
	if selected_class:
		self.selected_class = selected_class

			
	# TODO: Move to method, clean up
	var has_no_classes = item_manager.classes.size() == 0
	if has_no_classes:
		change_display_name_button.set_disabled(has_no_classes)		
		duplicate_button.set_disabled(true)
		save_button.set_disabled(true)
		save_all_button.set_disabled(true)
		save_all_button.set_disabled(true)
		rename_button.set_disabled(true)
		add_button.set_disabled(true)
		delete_button.set_disabled(true)
		copy_id_button.set_disabled(true)
		edit_class_button.set_disabled(true)
		copy_get_item_button.set_disabled(true)
		no_classes.show()
		instance_details.hide()
		class_overview.hide()
		id_label.set_text("No Classes")
		
		
	# An item was selected
	if selected_item:
		# Context was lost, e.g. because of changes to the classes. Reload.
		if selected_item and not selected_item.get("_id"):
			self.item_manager.load_manager()
			self.item_tree.load_tree(true)
			selected_item = item_tree.select_first_element()
		
		change_display_name_button.set_disabled(false)		
		duplicate_button.set_disabled(false)		
		save_button.set_disabled(false)
		save_all_button.set_disabled(false)
		rename_button.set_disabled(false)
		add_button.set_disabled(false)
		delete_button.set_disabled(false)
		copy_id_button.set_disabled(false)
		edit_class_button.set_disabled(false)
		copy_get_item_button.set_disabled(false)

		self.selected_item = selected_item
		self.selected_id = selected_item._id
		class_overview.hide()
		no_classes.hide()
		instance_details.show()
		if selected_item._display_name == selected_id:
			id_label.set_text(selected_id)
		else:
			id_label.set_text(selected_item._display_name + " (" +  selected_id + ")")
		
		class_properties.build_properties(selected_item)
		custom_properties.build_properties(selected_item)
	# A class was selected
	elif selected_class:
		change_display_name_button.set_disabled(true)
		duplicate_button.set_disabled(true)
		save_button.set_disabled(true)		
		save_all_button.set_disabled(false)		
		rename_button.set_disabled(false)
		add_button.set_disabled(false)
		delete_button.set_disabled(false)
		copy_id_button.set_disabled(false)
		edit_class_button.set_disabled(false)
		copy_get_item_button.set_disabled(true)
		self.selected_item = null
		self.selected_id  = null
		id_label.set_text(selected_class.capitalize())
		if item_manager.invalid_classes.has(selected_class):
			class_overview.set_label("There is a problem with this class, please check if there are any issues. Press 'Reload' once you are ready.")
		else:
			class_overview.set_label("")	
		class_overview.show()
		instance_details.hide()
		no_classes.hide()



func _on_ItemTree_on_new_item_created(new_item):
	selected_item = new_item


func create_shortcut(keys):
	var short_cut = ShortCut.new()
	var input_event = InputEvent()
	input_event.type = InputEvent.KEY
	input_event.ID = keys
	short_cut.set_shortcut(input_event)

# TODO: Implement
func warn_about_reload():
	if item_manager.has_unsaved_items():
		input_dialog.popup(self, "reload_confirmed", tr("Confirm reload"), tr("Some changes have not been saved. \nThey will be discarded if you proceed. Are you sure you want to perform this action?"))	


func reload():
	item_manager.load_manager()
	item_tree.load_tree(true)
	if item_manager.get_item(selected_class, selected_id):
		item_tree.select_item(item_manager.get_item(selected_class, selected_id))
		

func toggle_item_dirty_state(item):
	item._dirty = true
	item_tree.set_tree_item_label_text(item)


# Validation takes place in the item manager
func _on_NewCustomPropertyDialog_confirmed():
	var custom_property_id = new_custom_property_name.get_text().strip_edges()
	var custom_property_type = new_custom_property_type_options.get_selected_metadata()
	var success = item_manager.add_custom_property(selected_item, custom_property_id, custom_property_type)
	if success:
		item_tree.set_tree_item_label_text(selected_item)
		toggle_item_dirty_state(selected_item)
		custom_properties.build_properties(selected_item)


# TODO: Show confirmation dialog
func delete_custom_property(property_name):
	item_manager.delete_custom_property(selected_item, property_name)
	toggle_item_dirty_state(selected_item)
	custom_properties.build_properties(selected_item)

	
# TODO: New Class Dialog is still a mess
func _on_AddClassButton_button_down():
	new_item_class_name.set_text("")
	new_item_class_icon.set_text("")
	new_item_class_icon_dialog.set_current_path("")	
	new_item_class_dialog.popup_centered()
	new_item_class_name.grab_focus()


func _on_NewClassDialog_confirmed():
	var name = new_item_class_name.get_text().to_lower()
	var icon_path = new_item_class_icon.get_text()
	item_manager.create_class(name, icon_path)
	item_tree.load_tree()
	item_tree.select_class(name)
	reload()
	edit_class()


# New Class Dialog
func _on_NewClassIconSearchButton_button_down():
	new_item_class_icon_dialog.popup_centered()

# Icon for new class was selected
func _on_NewClassIconFileDialog_file_selected(path):
	new_item_class_icon.set_text(path)

# General handler for a lot of actions to centralize the GUI logic a bit
func handle_actions(action, argument = ""):
	if action == "add":
		input_dialog.popup(self, "_on_add_item_confirmed", tr("New Item"), tr("Please enter an ID for and optionally a display name the new item"), tr("ID"), "", tr("Display Name (optional)"), "")
	elif action == "rename":
		if selected_item:
			input_dialog.popup(self, "_on_rename_item_confirmed", tr("Rename Item"), tr("Please enter a new ID for this item."), "ID", selected_id)
		else:
			input_dialog.popup(self, "_on_rename_class_confirmed", tr("Rename Class"), tr("Please enter a new name for this class. All pending changes will be discarded!"), "ID", selected_class)
	elif action == "duplicate":
		var new_display_name = ""
		if selected_item._dirty:
			input_dialog.popup(self, "item_duplication_failed", tr("Item duplication failed"), tr("Before duplicating this item, please first save it."))			
			return
		selected_item._display_name = ""
		input_dialog.popup(self, "_on_duplicate_confirmed", tr("Duplicate Item"), tr("Please enter a new ID for this item"), "ID", selected_id, tr("Display Name (optional)"), new_display_name)
	elif action == "save":
		item_manager.save_item(selected_item)
		item_tree.load_tree()
			#reload()
	elif action == "save_all":
		item_manager.save_all_items()
		item_tree.load_tree()
		#reload()
	elif action == "reload":
		item_manager.load_manager()
		reload()
	elif action == "new_class":
		_on_AddClassButton_button_down()			# TODO: Incorporate into dialog handling
	elif action == "delete":
		if selected_item:
			input_dialog.popup(self, "_on_delete_item_confirmed", tr("Delete Item"), tr("Are you sure you want to delete this item?"))
		else:
			input_dialog.popup(self, "_on_delete_class_confirmed", tr("Delete Class"), tr("Are you sure you want to delete class along with all items?"))
	elif action == "options":
		options_screen.popup_centered()
	elif action == "edit_class":
		edit_class()		
	elif action == "copy_id":
		copy_id()
	elif action == "copy_get_item":
		copy_get_item()
	elif action == "change_display_name":
		input_dialog.popup(self, "change_display_name", tr("Change Display Name"), tr("Please enter a display name for this item."), "Display Name", selected_item._display_name)
	elif action == "add_custom_property":
		new_custom_property_name.set_text("")
		new_custom_property_dialog.popup_centered()
		new_custom_property_name.grab_focus()
		
#########################################################################
# Handlers										#
#########################################################################

func _on_add_item_confirmed(id, display_name):
	var new_item = item_manager.create_and_add_new_item(selected_class, id, display_name)
	if new_item:
		item_tree.add_leaf(new_item, true)
		
	
func _on_rename_item_confirmed(id):
	item_manager.rename_item(selected_item, id)
	reload()
	
	
func _on_rename_class_confirmed(name):
	item_manager.rename_class(selected_class, name)
	reload()
	

func _on_duplicate_confirmed(id, display_name):
	var duplicated_item = item_manager.duplicate_item(selected_item, id, display_name, false)
	item_tree.add_leaf(duplicated_item, true)
	reload()
		
func _on_delete_item_confirmed():
	item_manager.delete_item(selected_item)
	reload()
	
	
func _on_delete_class_confirmed():
	item_manager.delete_class(selected_class)
	if item_manager.classes.size() > 0:
		item_tree.select_class(item_manager.class_names[0])
	else:
		change_item_context(null, null)
	reload()	
	
#########################################################################
# Buttons on the right													#
#########################################################################
func change_display_name(new_name):
	selected_item._display_name = new_name
	toggle_item_dirty_state(selected_item)
	change_item_context(selected_item, selected_class)
		
func copy_id():
	if selected_item:
		OS.set_clipboard(selected_id)
	else:
		OS.set_clipboard(selected_class)

func copy_get_item():
	if selected_item:
		var copy_string = "data.get_item(\"" + selected_class + "\", \"" + selected_id + "\")"
		OS.set_clipboard(copy_string)
		
						
func edit_class():
	var script = item_manager.classes[selected_class]
	emit_signal("class_edit_requested", script)

#####################################################
# OTHERS
#####################################################
	
func show_warning(title, text):
	warn_dialog.set_title(title)
	warn_dialog.set_text(text)
	warn_dialog.popup_centered()


func log_text(text):
	var file = File.new()
	file.open("res://test.log", File.READ_WRITE)
	var old_text = file.get_as_text()
	var date = str(OS.get_datetime()["hour"]) + ":" + str(OS.get_datetime()["minute"]) + ":" + str(OS.get_datetime()["second"]) + "\t"
	file.store_line(old_text + date + text)


