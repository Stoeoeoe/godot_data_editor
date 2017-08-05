extends "res://addons/godot_data_editor/data_item.gd"

export(String) var name = ""
export(Texture) var icon = null
export(int, 0, 9999) var price = 0
export(String, "Armor Shop", "Weapon Shop", "Inn", "Travelling Salesman") var seller = "Armor Shop"
export(String, MULTILINE) var description = ""

func _init(id).(id):
	pass
