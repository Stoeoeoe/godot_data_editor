# Godot Data Editor
This repository hosts a plugin for the [Godot Engine]. It allows users to enter data items based on Godot classes which are then serialized in either as json or binaries. Serialized items may be encrypted if desired.

# Features
* Support for binary or json serialization
* Create data classes with the click of a button
* Use gdscript to add properties and logic to your data classes, all instances will be Nodes
* Make use of the built-in [export property hints]
* Add instance-specific custom properties 
* Access data with a simple API using the _data_ singleton
* ALPHA: Use the notification/observer system to react to changes in data items 
* ALPHA: Encrypt your data files

# Screenshots
![editor_screenshot]
![class_screenshot]
![data_access]

# Installation
* Download/clone this repository
* Open your project folder, e.g. "../MyGame/"
* Copy the "addons" folder into your project folder
* Open your project in the editor and navigate to the plugin (Scene -> Project Settings -> Plugins)
* The plugin "godot_data_editor" should now appear, change the status from "Inactive" to "Active"
* IMPORTANT: Add the _data_ singleton which allows you to access the data later on. To do so, go to the Project Settings -> AutoLoad, then enter "addons/godot_data_editor/data.gd" as path and "data" as Node Name. Save the singleton by clicking on "Add".
![singleton]

You can also download the addon in the Asset Lib, make sure to exclude the "demo" folder though :)

# System Requirements
The plugin was written for version *2.1.3* of the Godot Engine. Upcoming minor versions should be supported as well.
It is very likely that a number of changes will be necessary, once Godot 3 is released. 

# API / Demo
There is a demo project available which shows how the plugin could be used in practice. Clone the repository and open the engine.cfg in the "demo" directory. 

Working with data is rather simple, use the provided _data_ class to access items. The following code snippets demonstrates item retrieval as well as the observation feature:
```gdscript
extends Node

func _ready():
	# Get a single item
	var herb = data.get_item("shop_item", "herb")
	var price = herb.price
	
	# Get all items as dictionary (key: id, value: item)
	var shop_items = data.get_items("shop_item")
	for shop_item in shop_items.values():
		print(shop_item.price)
	pass
	
	#######################################
	# Observe Properties:
	# Please note that you currently have to update properties using the "update_property" to make use of this feature
	#######################################

	# Be notified when something about this herb changes
	data.observe_item(self, herb, "herb_changed")
	herb.update_property("name", "better_herb")
	
	# Be notified when the price of this herb changes, 
	data.observe_item_property(self, herb, "price", "herb_price_changed")
	herb.update_property("price", 500)	

	# Be notified when any item changes
	var doge_axe = data.get_item("shop_item", "doge_axe")
	data.observe_class(self, "shop_item", "shop_item_changed")
	doge_axe.update_property("price", 500)	
		
	# Overkill: be notified about everything
	data.observe_all_changes(self, "something_changed")

	#######################################
	# Stop Observing:
	# When you are no longer interested in updates, simply unsubscribe/stop observing
	#######################################
	data.stop_observing_item_property(self, herb, "price")
	data.stop_observing_item(self, herb)
	data.stop_observing_class(self, "shop_item")
	data.stop_observing_changes(self)

		
func herb_changed(item, property, value):
	print("Something about this herb changed!")
	
func herb_price_changed(item, property, value):
	print("Herb price changed!")
	
func shop_item_changed(item, property, value):
	print(item.name + " changed! " + property + " : " + str(value))

func something_changed(item, property, value):
	print("I guess something changed.")
```

# Please Contribute!
Please feel free to contribute. Unfortunately, the code base still is not documented that well and there are a number of bugs which will need to be ironed out. I am sure that there are many things I have been doing wrong, especially in regard to memory management.

# Known Issues
* The "Rename Class" feature may not properly rename the class file if it still in use
* In some cases, the controls are not correctly resized - pressing "Reload" should usually do the trick though
* There is no support for undo/redo
* Pressing Ctrl+S will not save the data items but the current scene
* Originally, the _data_ singleton was stored automatically in the engine.cfg configuration as soon as the plugin was loaded. This has lead to various issues though. For that reason, _data_ must currently be added manually. 
* Internationalization is still lacking
* Under certain circumstances, integers cannot be entered
* There is an issue with the color control whereby the default value indicated in the class is not being taken into account
* No Godot 3 support yet ;)

Please post any issues you encounter.

# HALP! Something went wrong!
Stay calm, most issues can be resolved by either pressing the "Reload" button or deactivating and activating the plugin. If the problem persists, there may be an issue with your data. Check if the name of the class (which are stored in the "classes" folder by default) is the same as the folder name of your instances (by default called "data"). If this is the case, there might be a conflict with duplicate IDs or the like. Please post an issue here if this happened without any external influence (e.g. you edited the files manually in another editor). 



[Godot Engine]: <https://github.com/godotengine/godot>
[singleton]: <http://docs.godotengine.org/en/stable/learning/step_by_step/singletons_autoload.html>
[export property hints]: <http://docs.godotengine.org/en/latest/learning/scripting/gdscript/gdscript_basics.html#exports>
[editor_screenshot]: https://github.com/Stoeoeoe/godot_data_editor/blob/master/screenshots/editor.png "The Godot Data Editor"
[class_screenshot]: https://github.com/Stoeoeoe/godot_data_editor/blob/master/screenshots/class.png "Example Class"
[data_access]: https://github.com/Stoeoeoe/godot_data_editor/blob/master/screenshots/data_access.png "Example Data Access"
[singleton]: https://github.com/Stoeoeoe/godot_data_editor/blob/master/screenshots/singleton.png "Data Singleton"
