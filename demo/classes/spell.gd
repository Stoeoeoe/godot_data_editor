extends "res://addons/godot_data_editor/data_item.gd"

export(String) var name = ""
export(String, MULTILINE) var description = ""
export(String, "water", "fire", "wind", "earth") var element = "water"
export(Texture) var icon = null
export(int, 0, 9999) var base_damage = 0
export(String, "One Enemy", "All Enemies", "One Player", "All Players") var target = "One Enemy" 
export(PackedScene) var effect = null
export(Sample) var sound = null

func _init(id).(id):
	pass
	
