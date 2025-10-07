extends CardData
class_name MonsterCardData

@export var hp: int
@export var attack: int


func actLabel(label: Label):
	var effect = "placeholder"
	label.text = "Ataque: %d" % [attack] + "\nHP: %d" % [hp] + "\nEfecto:"  + effect
	
