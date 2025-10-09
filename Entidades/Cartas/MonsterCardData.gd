extends CardData
class_name MonsterCardData

@export var hp: int
@export var attack: int
@export var traits: Array[TraitBase] = []
var maxHp:int = hp


func actLabel(label: Label):
	var effect = "placeholder"
	label.text = "Ataque: %d" % [attack] + "\nHP: %d" % [hp] + "\nEfecto:"  + effect
	
func get_MaxHp():
	return maxHp
	
