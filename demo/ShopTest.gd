extends Node2D

onready var buttons_array = get_node("ShopButtons")
onready var shop_dialog = get_node("ShopDialog")


func _ready():
	var shop_types = ["Armor Shop", "Weapon Shop", "Inn", "Travelling Salesman"]
	for shop_type in shop_types:
		buttons_array.add_button(shop_type)


func _on_ShopButtons_button_selected( button_idx ):
	var text = buttons_array.get_button_text(button_idx)
	var all_merchants = data.get_items("merchant")
	for merchant in all_merchants.values():
		if merchant.name == text:
			shop_dialog.create_shop(merchant)
			shop_dialog.popup_centered()