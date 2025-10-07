extends Node2D


@onready var grid_monstruos: Node2D = $GridMonstruos
@onready var deck_drawer: Node = $DeckDrawer

var cards_per_turn: int = 2  # Cantidad de cartas por turno
var current_turn: int = 0
var deck_index: int = 0

func _ready():
	turn_loader()

func _on_turn_button_pressed():
	#place_cards_randomly()
	pass

func turn_loader():
	for i in cards_per_turn:
		place_monster()

func place_monster():
	var monster:MonsterCardData = deck_drawer.draw()
	grid_monstruos.invoke_random_piece(monster)

func change_turn():
	cards_per_turn += 1
	current_turn += 1
	#update_turn()
	
func update_turn_display():
	pass
	#turn_label.text = "Turno: " + str(current_turn)
	
	# Verificar si el botón debe estar activo
	#var empty_slots = get_empty_slots()
	#var has_cards = deck_index < deck_cards.size()
	
	#turn_button.disabled = empty_slots.is_empty() or not has_cards
