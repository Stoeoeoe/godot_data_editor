extends Node

var item_manager = null
var items = {}
var values = {}


func _init():
	# Caution: This item manager may not be in sync with the one used by the editor
	self.item_manager = preload("item_manager.gd").new()
	self.items = item_manager.items


func get_item(item_class, id):
	return item_manager.get_item(item_class, id)
	 

func get_items(item_class):
	return item_manager.get_items(item_class)


func _load_item(item_class, id):
	items[item_class][id] = item_manager.load_item(item_class, id)


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
		if has_user_signal("@any_value_changed"):
			emit_signal("@any_value_changed", item, property, value)
	
		var signal_name = ""
		signal_name = "@" + item_class
		# Class signal
		if has_user_signal(signal_name):
			emit_signal(signal_name, item, property, value)
			
		# Item signal
		signal_name = "@" + item_class + "|" + id
		if has_user_signal(signal_name):
			emit_signal(signal_name, item, property, value)
			
		# Property signal
		signal_name = "@" + item_class + "|" + id + "|" + property
		if has_user_signal(signal_name):
			emit_signal(signal_name, item, property, value)
			
		return true
	else:
		return false
		
func observe_all_changes(observer, method, binds=[], flags = 0):
	var signal_name = "@any_value_changed"
	self.add_user_signal(signal_name)		# TODO: Args
	self.connect(signal_name, observer, method, binds, flags)
	
func observe_class(observer, item_class, method, binds=[], flags = 0):
	var signal_name = "@" + item_class
	self.add_user_signal(signal_name)		# TODO: Args
	self.connect(signal_name, observer, method, binds, flags)

func observe_item(observer, item, method, binds=[], flags = 0):
	var signal_name = "@" + item._class + "|" + item._id
	if not has_user_signal(signal_name):
		self.add_user_signal(signal_name)		# TODO: Args
	self.connect(signal_name, observer, method, binds, flags)


func observe_item_property(observer, item, property, method, binds=[], flags = 0):
	var signal_name = "@" + item._class + "|" + item._id + "|" + property
	if not has_user_signal(signal_name):
		self.add_user_signal(signal_name)		# TODO: Args
	self.connect(signal_name, observer, method, binds, flags)

func _get_relevant_connections():
	var relevant_connections = []
	var signals = get_signal_list()
	for s in signals:
		var name = s["name"]
		if name.begins_with("@"):
			for c in get_signal_connection_list(name):
				relevant_connections.append(c)
	return relevant_connections


func stop_observing_class(observer, item_class):
	var connection_list = _get_relevant_connections()
	for connection in connection_list:
		var target = connection["target"]
		var signal_info = connection["signal"].replace("@", "").split("|")
		if signal_info.size() == 1 and signal_info[0] == item_class and target == observer: 
			self.disconnect(connection["signal"], target, connection["method"])

func stop_observing_item(observer, item):
	var connection_list = _get_relevant_connections()
	for connection in connection_list:
		var target = connection["target"]
		var signal_info = connection["signal"].replace("@", "").split("|")
		if signal_info.size() == 2 and signal_info[0] == item._class and signal_info[1] == item._id and target == observer: 
			self.disconnect(connection["signal"], target, connection["method"])
	
func stop_observing_item_property(observer, item, property):
	var connection_list = _get_relevant_connections()
	for connection in connection_list:
		var target = connection["target"]
		var signal_info = connection["signal"].replace("@", "").split("|")
		if signal_info.size() == 3 and signal_info[0] == item._class and signal_info[1] == item._id and signal_info[2] == property and target == observer: 
			self.disconnect(connection["signal"], target, connection["method"])
			
func stop_observing_changes(observer):
	var connection_list = _get_relevant_connections()
	for connection in connection_list:
		var target = connection["target"]
		if target == observer:
			self.disconnect(connection["signal"], target, connection["method"])
					
			
#	observer.disconnect(

	
func set_item_progress(item, property, value):
	set_progress(item._class, item._id, property, value)
	
func get_progress_by_item(item):
	

	