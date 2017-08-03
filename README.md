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

# Installation
* Open your project folder, e.g. "../MyGame/"
* Create a folder named "addons" (if not already present)
* In addons, create a folder named "godot_data_editor" 
* Copy the content of this repository into it. You may remove the "sceenshots"  ;)
* Open your project in the editor and navigate to the plugin (Scene -> Project Settings -> Plugins)
* The plugin "godot_data_editor" should now appear, change the status from "Inactive" to "Active"
* Restart the editor to make sure that the _data_ singleton is loaded properly

I intend to upload the plugin to the AssetLib, once I feel it is stable enough.

# System Requirements
The plugin was written for version *2.1.3* of the Godot Engine. Upcoming minor versions should be supported as well.
It is very likely that a number of changes will be necessary, once Godot 3 is released. 

# API / Tutorial
I created a little video which shows how to use the plugin to create a simple shop system:  [[Link to video which does not exist yet :) ]]

Working with data is rather simple, use the provided _data_ class to access the items. The following code snippets demonstrates item retrieval as well as the observation feature:
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
Please feel free to contribute. Unfortunately, the code base still is not documented that well and there are a number of bugs which will need to be ironed out. I am sure that there are a number of things I have been doing wrong, e.g. performance/memory management issues.

# Known Issues
* The "Rename Class" feature may not properly rename the class file if it still in use
* There are a number of reference issues
* In some cases, the controls are not properly resized - pressing "Reload" should usually do the trick though
* A number of operations will perform a complete refresh of all data, which causes unsaved changes to disappear. This was done to prevent inconsistencies
* There is no support for undo/redo
* Pressing Ctrl+S to save while in the data editor may temporarily hide unsaved items
* The _data_ singleton is only visible in the editor when the project is being restarted. This seems to be a limitation of the engine which does not allow reload the engine.cfg file
* The "class overview" screen is lacking any kind of useful content

# HALP! Something went wrong!
Stay calm, most issues can be resolved by either pressing the "Reload" button or activating and deactivating the plugin. If the problem persists, there is likely an issue with your data. Check if the name of the class (which are stored in the "classes" folder by default) is the same as the folder name of your instances (by default called "data"). If this is the case, there might be a conflict with duplicate IDs or the like. Please post an issue here if this happened without any external influence (e.g. you edited the files manually in another editor).



[Godot Engine]: <https://github.com/godotengine/godot>
[export property hints]: <http://docs.godotengine.org/en/latest/learning/scripting/gdscript/gdscript_basics.html#exports>
[editor_screenshot]: https://github.com/Stoeoeoe/godot_data_editor/blob/master/screenshots/editor.png "The Godot Data Editor"
[class_screenshot]: https://github.com/Stoeoeoe/godot_data_editor/blob/master/screenshots/class.png "Example Class"