extends Node2D
class_name WeaponSpawner

@onready var grid: Node2D = $WeaponGrid
@onready var turn_button = $"../CanvasLayer/PasarTurno"



func _ready():
	turn_loader()
	turn_button.pressed.connect(_on_turn_button_pressed)

func _on_turn_button_pressed():
	if WeaponDeck.size() > 0:
		turn_loader()
	pass

func turn_loader():
	for i in grid.get_empty_slots().size():
		place_weapon()

func place_weapon():
	if WeaponDeck.size() > 1: 
		var weapon:WeaponCardData = WeaponDeck.draw()
		grid.invoke_random_piece(weapon)
