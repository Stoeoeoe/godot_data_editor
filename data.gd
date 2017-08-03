extends Node

var item_manager = null
var items = {}
var values = {}

signal any_value_changed(item, property, value)


var signals_any_value_changed = []
var signals_item_class_any_value_changed = []
var signals_item_any_values_changed = []
var signals_item_value_changed = []

func _init():
	self.item_manager = preload("item_manager.gd").new()
	self.items = item_manager.items

# TODO: Allow eager loading

		
		
func get_item(item_class, id):
	return item_manager.get_item(item_class, id)
	 
func get_items(item_class):
	return item_manager.get_items(item_class)

#	if items[item_class].has(id):
#		return items[item_class][id]
#	else:
#		_load_item(item_class, id)
#		return items[item_class][id]

func _load_item(item_class, id):
	items[item_class][id] = item_manager.load_item(item_class, id)
#	values[item_class][id] = {}

func load_values_of_all_items():
	pass

func load_item_value(item, property):
	return get_progress(item._class, item._id, property)
	
	
func get_progress(item_class, id, property):
	if items[item_class].has(id) and items[item_class][id].has(property):
		return items[item_class][id][property]

	
func set_progress(item_class, id, property, value):
	var item = item_manager.get_item(item_class, id)
	var has_value = item.get(property)
	if item and has_value:
		item.set(property, value)
		emit_signal("any_value_changed", item, property, value)
	
		var signal_name = ""
		signal_name = item_class
		# Class signal
		if has_user_signal(signal_name):
			emit_signal(signal_name, item, property, value)
			
		# Item signal
		signal_name = item_class + "|" + id
		if has_user_signal(signal_name):
			emit_signal(signal_name, item, property, value)
			
		# Property signal
		signal_name = item_class + "|" + id + "|" + property
		if has_user_signal(signal_name):
			emit_signal(signal_name, item, property, value)
	
		return true
	else:
		return false
		
func observe_all_changes(observer, method, binds=[], flags = 0):
	self.connect("any_value_changed", observer, method, binds, flags)
	
func observe_class(observer, item_class, method, binds=[], flags = 0):
	self.add_user_signal(item_class)		# TODO: Args
	self.connect(item_class, observer, method, binds, flags)

func observe_item(observer, item, method, binds=[], flags = 0):
	var signal_name = item._class + "|" + item._id
	if not has_user_signal(signal_name):
		self.add_user_signal(signal_name)		# TODO: Args
	self.connect(signal_name, observer, method, binds, flags)

func observe_item_property(observer, item, property, method, binds=[], flags = 0):
	var signal_name = item._class + "|" + item._id + "|" + property
	if not has_user_signal(signal_name):
		self.add_user_signal(signal_name)		# TODO: Args
	self.connect(signal_name, observer, method, binds, flags)

func stop_observing_all_changes(observer):
	pass
#	observer.disconnect(
	
#TODO: func block_signals()

	
func set_item_progress(item, property, value):
	set_progress(item._class, item._id, property, value)
	
func get_progress_by_item(item):
	

	