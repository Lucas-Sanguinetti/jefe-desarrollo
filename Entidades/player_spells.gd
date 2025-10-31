extends HBoxContainer
class_name Hand

signal card_played(spell: SpellCardData, target)

@export var max_hand_size: int = 7
@export var card_spacing: int = 10

var cards_in_hand: Array[CartaHechizo] = []
var selected_card: CartaHechizo = null

func _ready():
	add_theme_constant_override("separation", card_spacing)

func add_card(spell_data: SpellCardData) -> bool:
	if cards_in_hand.size() >= max_hand_size:
		push_warning("Mano llena, no se puede agregar más cartas")
		return false
	

	var card: CartaHechizo = spell_data.escena.instantiate()
	card.spell_data = spell_data
	
	add_child(card)
	cards_in_hand.append(card)
	
	# Conectar señales
	card.card_selected.connect(_on_card_selected)
	card.card_double_clicked.connect(_on_card_double_clicked)
	card.card_used.connect(_on_card_used)
	
	# Animación de entrada (opcional)
	card.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(card, "modulate:a", 1.0, 0.3)
	
	return true

func remove_card(card: CartaHechizo) -> SpellCardData:
	var spell_data = card.spell_data
	cards_in_hand.erase(card)
	
	# Animación de salida
	var tween = create_tween()
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_callback(card.queue_free)
	
	return spell_data

func _on_card_selected(card: CartaHechizo):
	# Deseleccionar otras cartas
	for c in cards_in_hand:
		if c != card:
			c.highlight(false)
	
	selected_card = card
	
	# Si requiere objetivo, activar modo de selección de enemigos
	if card.spell_data.target_type == SpellCardData.TargetType.ENEMY:
		get_tree().call_group("enemies", "set_targetable", true)

func _on_card_double_clicked(card: CartaHechizo):
	var target = null
	
	match card.spell_data.target_type:
		SpellCardData.TargetType.SELF:
			target = get_tree().get_first_node_in_group("player")
		SpellCardData.TargetType.ALL_ENEMIES:
			target = get_tree().get_nodes_in_group("enemies")
		SpellCardData.TargetType.RANDOM_ENEMY:
			var enemies = get_tree().get_nodes_in_group("enemies")
			if enemies.size() > 0:
				target = enemies.pick_random()
	
	if target:
		card_played.emit(card.spell_data, target)
		remove_card(card)
		selected_card = null

func _on_card_used(card: CartaHechizo, target):
	card_played.emit(card.spell_data, target)
	remove_card(card)
	selected_card = null
	
	# Desactivar modo de selección
	get_tree().call_group("enemies", "set_targetable", false)

func cancel_selection():
	if selected_card:
		selected_card.highlight(false)
		selected_card = null
	get_tree().call_group("enemies", "set_targetable", false)

func get_hand_size() -> int:
	return cards_in_hand.size()

func is_hand_full() -> bool:
	return cards_in_hand.size() >= max_hand_size
