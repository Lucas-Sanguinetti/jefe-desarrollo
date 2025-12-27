extends Node2D

@onready var grid: Node2D = $WeaponGrid

var cards: int = 1  # Cantidad de cartas 


func _ready():
	turn_loader()

func _on_turn_button_pressed():
	if WeaponDeck.size() > 0:
		turn_loader()
	pass

func turn_loader():
	place_weapon()

func place_weapon():
	print("Ya me puse en el grid")
	var weapon:WeaponCardData = WeaponDeck.drawTutorial()
	grid.invoke_random_piece(weapon)
