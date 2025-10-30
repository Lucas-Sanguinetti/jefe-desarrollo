extends CardData
class_name MonsterCardData

@export var hp: int
@export var attack: int
@export var traits: Array[TraitBase] = []
@export var nivel:int = 1
@export var element:Texture2D = preload("uid://cfghlodo6mm6e")
@export var backsprite:Texture2D = preload("uid://bm7c1ddxe8pm6")
var maxHp:int = hp


func actLabel(label: Label):
	#var effect = "placeholder"
	#label.text = "Ataque: %d" % [attack] + "\nHP: %d" % [hp] + "\nEfecto:"  + effect
	var text = "Ataque: %d\n" % [attack]
	text += "Vida: %d\n" % [hp]
	
	
	# Agregar traits
	if not traits.is_empty():
		for rasgo in traits:
			if rasgo is Endurecer:
				text += "* %s " % [rasgo.trait_name]
				text += "  %s\n" % [rasgo.resistencia]
			else:
				text += "* %s\n" % [rasgo.trait_name]
			text += " %s\n" % [rasgo.trait_description]
			
				
	else:
		text += "Sin traits\n"
	
	label.text = text
	
func get_MaxHp():
	return maxHp
	
