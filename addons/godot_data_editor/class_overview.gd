tool
extends PanelContainer



func _ready():
	pass

func set_label(text):
	get_node("Panel/Body/Label").set_text(text)
