tool
extends Panel

var item = null
var property_item_class = preload("property_item.tscn")
var remove_icon = preload("icons/icon_remove.png")


onready var custom_properties_box = 			get_node("Body/Scroll/CustomProperties")
onready var no_custom_properties_label = get_node("Body/Scroll/CustomProperties/NoCustomPropertiesLabel")

onready var item_manager =  null				# Item Manager, used to load, modify and save items

signal on_item_changed(item)
signal new_custom_property_created
signal custom_property_add_requested
signal custom_property_delete_requested(custom_property_id)

#TODO: Somehow the properties are initialized twice

func _ready():
	pass
	self.item_manager = Globals.get("item_manager")
		
func build_properties(item):
	self.item = item
	var properties = item._custom_properties
	for node in custom_properties_box.get_children():
		if node.has_meta("property"):
			custom_properties_box.remove_child(node)
	
	var number_of_properties = 0
	var property_names = properties.keys()
	property_names.sort()
	for property_name in property_names:
		no_custom_properties_label.hide()
		number_of_properties += 1
		
		var container = MarginContainer.new()
		var property_item = property_item_class.instance()
		var type = properties[property_name][0]

		# If there already is a value, read it, otherwise set it to null
		var value = null
		if properties[property_name].size() == 2:
			value = properties[property_name][1]
			
		property_item.initialize(property_name, type, value, 0, "", true)
		property_item.connect("custom_property_delete_requested", self, "emit_signal", ["custom_property_delete_requested", property_name, ])
		property_item.connect("property_item_load_button_down", self, "_property_item_requests_file_dialog", [])
		var changed_values = []
		property_item.connect("on_property_value_changed", self, "item_changed", changed_values)

		container.set_meta("property", true)
		container.add_child(property_item)
		custom_properties_box.add_child(container)

	pass
	if number_of_properties == 0:
		no_custom_properties_label.show()	


# Fires signal when the item's custom properties is to be updated, delegates to data_editor_gui.
func item_changed(property, value):
	if item:
		item._custom_properties[property][1] = value
		emit_signal("on_item_changed", item)	


# Delegates the deletion 
func delete_custom_property(property_name):
	emit_signal("custom_property_delete_requested", property_name)
	

# Fires signal when the item's custom properties is to be updated, delegates to data_editor_gui.func _on_NewCustomPropertyButton_button_down():
func _on_NewCustomPropertyButton_button_down():
	emit_signal("custom_property_add_requested")