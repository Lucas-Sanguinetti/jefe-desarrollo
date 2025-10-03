extends Node2D

@onready var grid: Node2D = $WeaponGrid

var cards: int = 6  # Cantidad de cartas 


func _ready():
	turn_loader()

func _on_turn_button_pressed():
	if WeaponDeck.size() > 0:
		turn_loader()
	pass

func turn_loader():
	for i in cards:
		place_monster()

func place_monster():
	var weapon:WeaponCardData = WeaponDeck.draw()
	grid.invoke_random_piece(weapon)
