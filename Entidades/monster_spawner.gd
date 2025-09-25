extends Node

@export var monsterDeck: PackedScene
@onready var grid = $Grid
@onready var deck = $Deck
@onready var turn_button = $TurnButton
@onready var turn_label = $UI/TurnLabel

var card_slots: Array[CardSlot] = []
var deck_cards: Array[Node2D] = []
var cards_per_turn: int = 2  # Cantidad de cartas por turno
var current_turn: int = 0
var deck_index: int = 0

func _ready():
	# Inicializar slots
	#setup_card_slots()
	
	# Inicializar deck
	#setup_deck()
	
	# Conectar botón
	#turn_button.pressed.connect(_on_turn_button_pressed)
	
	# Actualizar UI
	#update_turn_display()
	pass

func setup_card_slots():
	# Obtener todos los CardSlots del grid
	for child in grid.get_children():
		if child is CardSlot:
			card_slots.append(child)

func setup_deck():
	# Obtener todas las cartas del deck en orden
	for child in deck.get_children():
		deck_cards.append(child)

func _on_turn_button_pressed():
	place_cards_randomly()

func place_cards_randomly():
	# Verificar si tenemos cartas disponibles
	if deck_index >= deck_cards.size():
		print("No hay más cartas en el deck")
		turn_button.disabled = true
		return
	
	# Obtener slots vacíos
	var empty_slots = get_empty_slots()
	
	if empty_slots.is_empty():
		print("No hay slots vacíos")
		return
	
	# Calcular cuántas cartas colocar
	var cards_to_place = min(cards_per_turn, deck_cards.size() - deck_index, empty_slots.size())
	
	# Mezclar los slots vacíos para colocación aleatoria
	empty_slots.shuffle()
	
	# Colocar las cartas
	for i in range(cards_to_place):
		var card = deck_cards[deck_index]
		var slot = empty_slots[i]
		
		if slot.place_card(card):
			deck_index += 1
			print("Carta colocada en slot: ", slot.name)
	
	# Actualizar turno y UI
	current_turn += 1
	update_turn_display()

func get_empty_slots() -> Array[CardSlot]:
	var empty: Array[CardSlot] = []
	
	for slot in card_slots:
		if not slot.is_occupied:
			empty.append(slot)
	
	return empty

func update_turn_display():
	turn_label.text = "Turno: " + str(current_turn)
	
	# Verificar si el botón debe estar activo
	var empty_slots = get_empty_slots()
	var has_cards = deck_index < deck_cards.size()
	
	turn_button.disabled = empty_slots.is_empty() or not has_cards
