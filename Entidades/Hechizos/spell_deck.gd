class_name SpellDeck extends Node

@export var spell_Deck: Array[SpellCardData] = []
@export var starting_spells:Array[SpellCardData] = []
@export var cards_to_draw_first_turn: int = 1

var deck: Array[SpellCardData] = []
var start_spells: Array[SpellCardData] = []
var discard_pile: Array[SpellCardData] = []
var removed_pile: Array[SpellCardData] = []
var is_first_turn: bool = true

func _ready():
	initialize_deck()
	add_to_group("SpellDeck")

func initialize_deck():
	deck.clear()
	discard_pile.clear()
	removed_pile.clear()
	
	# Copiar hechizos iniciales al mazo
	for Hechizo in spell_Deck:
		deck.append(Hechizo)
	
	shuffle_deck()
	is_first_turn = true

func shuffle_deck():
	deck.shuffle()
# ============================================
# ROBAR CARTAS
# ============================================
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

func draw_initial_hand() -> Array[SpellCardData]:
	is_first_turn = false
	return starting_spells

func draw_turn_card() -> SpellCardData:
	if is_first_turn:
		push_warning("Usa draw_initial_hand() para el primer turno")
		return null
	
	return draw_card()
# ============================================
# Descartar CARTAS
# ============================================

func discard_card(hechizo: SpellCardData):
	if not hechizo:
		return
	# Si es de uso único, va a removed_pile (no vuelve al mazo)
	if hechizo.one_time_use:
		removed_pile.append(hechizo)
		print("SpellDeck: '%s' removida permanentemente (uso único)" % hechizo.name)
	else:
		# Va a discard_pile normal
		discard_pile.append(hechizo)
		print("SpellDeck: '%s' descartada" % hechizo.name)

# ============================================
# QUERIES
# ============================================
func get_deck_size() -> int:
	return deck.size()

func get_discard_size() -> int:
	return discard_pile.size()

func get_removed_size() -> int:
	return removed_pile.size()
	
func get_total_cards() -> int:
	return deck.size() + discard_pile.size()

func reset():
	initialize_deck()
