extends CardData
class_name WeaponCardData

@export var attack: int
@export var traits: Array[TraitBase] = []
@export var nivel:int = 1
@export var element:Texture2D = preload("uid://cfghlodo6mm6e")

func actLabel(label: Label):
	#var effect = "placeholder"
	#label.text = "Ataque: %d \nEfecto: " % [attack] + effect
	var text = "Ataque: %d\n" % [attack]
	
	# Agregar traits
	if not traits.is_empty():
		for rasgo in traits:
			text += "* %s\n" % [rasgo.trait_name]
			text += " %s\n" % [rasgo.trait_description]
	else:
		text += "Sin traits\n"
	
	label.text = text
