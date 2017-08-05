extends WindowDialog

onready var item_list = get_node("VBoxContainer/ItemList")


func create_shop(merchant):
	var items_of_this_merchant = []
	var all_shop_items = data.get_items("shop_item")
	for shop_item in all_shop_items.values():
		if shop_item.seller == merchant.name:
			items_of_this_merchant.append(shop_item)
			
	var i = 0
	item_list.clear()
	for shop_item in items_of_this_merchant:
		item_list.add_item(shop_item.name)
		item_list.set_item_metadata(i, shop_item)
		i = i + 1
		
	get_node("VBoxContainer/MerchantLabel").set_bbcode(merchant.name)
	get_node("VBoxContainer/GreetingLabel").set_text(merchant.greeting)
		
	