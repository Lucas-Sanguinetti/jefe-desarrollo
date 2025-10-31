class_name SpellDeck extends Node

@export var starting_spells: Array[SpellCardData] = []
@export var cards_to_draw_first_turn: int = 1

var deck: Array[SpellCardData] = []
var discard_pile: Array[SpellCardData] = []
var is_first_turn: bool = true

func _ready():
	initialize_deck()

func initialize_deck():
	deck.clear()
	discard_pile.clear()
	
	# Copiar hechizos iniciales al mazo
	for Hechizo in starting_spells:
		deck.append(Hechizo)
	
	shuffle_deck()
	is_first_turn = true

func shuffle_deck():
	deck.shuffle()

func draw_card() -> SpellCardData:
	if deck.is_empty():
		# Si el mazo está vacío, mezclar la pila de descarte
		if discard_pile.is_empty():
			push_warning("No hay más cartas para robar")
			return null
		
		deck = discard_pile.duplicate()
		discard_pile.clear()
		shuffle_deck()
		print("Mazo reabastecido desde la pila de descarte")
	
	return deck.pop_back()

func discard_card(Hechizo: SpellCardData):
	discard_pile.append(Hechizo)

func draw_initial_hand() -> Array[SpellCardData]:
	var cards: Array[SpellCardData] = []
	
	for i in range(cards_to_draw_first_turn):
		var card = draw_card()
		if card:
			cards.append(card)
	
	is_first_turn = false
	return cards

func draw_turn_card() -> SpellCardData:
	if is_first_turn:
		push_warning("Usa draw_initial_hand() para el primer turno")
		return null
	
	return draw_card()

func get_deck_size() -> int:
	return deck.size()

func get_discard_size() -> int:
	return discard_pile.size()
