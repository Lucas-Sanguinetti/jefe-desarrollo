extends CardData
class_name MonsterCardData

@export var hp: int
@export var attack: int
@export var traits: Array[TraitBase] = []
var maxHp:int = hp


func actLabel(label: Label):
	#var effect = "placeholder"
	#label.text = "Ataque: %d" % [attack] + "\nHP: %d" % [hp] + "\nEfecto:"  + effect
	var text = "Ataque: %d\n" % [attack]
	text += "Vida: %d\n" % [hp]
	
	
	# Agregar traits
	if not traits.is_empty():
		for rasgo in traits:
			text += "• %s\n" % [rasgo.trait_name]
			text += "  %s\n" % [rasgo.trait_description]
			if rasgo.trait_name == "Endurecer":
				text += "  %s\n" % [rasgo.resistencia]
	else:
		text += "Sin traits\n"
	
	label.text = text
	
func get_MaxHp():
	return maxHp
	
