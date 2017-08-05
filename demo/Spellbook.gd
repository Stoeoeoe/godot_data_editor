extends Panel

onready var spell_list = get_node("LeftVBox/ScrollContainer/SpellList")

var icon_spell_unknown = preload("res://graphics/icon_spell_unknown.png")

func _ready():
	var all_spells = data.get_items("spell")
	var i = 0
	for spell in all_spells.values():
		var icon = null
		if spell.icon:
			icon = load(spell.icon)
		else:
			icon = icon_spell_unknown
		spell_list.add_item(spell.name, icon)
		spell_list.set_item_tooltip(i, spell.name)
		spell_list.set_item_metadata(i, spell)
		i = i + 1
	
	spell_list.select(0)
	_on_SpellList_item_selected(0)

func _on_SpellList_item_selected( index ):
	var spell = spell_list.get_item_metadata(index)
	get_node("RightVBox/SkillName").set_text(spell.name)
	get_node("RightVBox/Description").set_text(spell.description)
	var element = data.get_item("element", spell.element)
	get_node("RightVBox/Type").set_bbcode("[color=#" + element.color.to_html() + "]" + element.name + "[/color]")
	get_node("RightVBox/BaseDamage").set_text("Base Damage: " + str(spell.base_damage))
