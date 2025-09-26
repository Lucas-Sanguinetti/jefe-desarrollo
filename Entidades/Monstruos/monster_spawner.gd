extends Node2D


@onready var grid_monstruos: Node2D = $GridMonstruos
@onready var deck_drawer: Node = $DeckDrawer
@onready var turn_button = $"../CanvasLayer/PasarTurno"

var cards_per_turn: int = 1  # Cantidad de cartas por turno


func _ready():
	turn_loader()
	turn_button.pressed.connect(_on_turn_button_pressed)

func _on_turn_button_pressed():
	if MonsterDeck.size() > 0:
		turn_loader()
	pass

func turn_loader():
	for i in cards_per_turn:
		place_monster()

func place_monster():
	var monster:MonsterCardData = deck_drawer.draw()
	grid_monstruos.invoke_random_piece(monster)
