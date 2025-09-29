extends Node


@export var weapons_data_cards: Array[WeaponCardData] 



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	weapons_data_cards.shuffle()



func draw():
	print("robe una carta")
	var weapon:WeaponCardData = weapons_data_cards[0]
	weapons_data_cards.remove_at(0)
	return weapon


func size():
	return weapons_data_cards.size()
