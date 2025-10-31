extends Node2D
class_name Hand

signal card_played(spell: SpellCardData, target)

@export var max_hand_size: int = 7
@export var card_spacing: float = 110.0  # Espaciado entre cartas
@export var card_scale: float = 1.0  # Escala de las cartas
@export var hover_lift: float = -20.0  # Cuánto sube la carta al hacer hover

var cards_in_hand: Array[CartaHechizo] = []
var selected_card: CartaHechizo = null
var waiting_for_target: bool = false
signal mouseEntered(carta: Carta)

func _ready():
	add_to_group("Hand")

func add_card(spell_data: SpellCardData) -> bool:
	if cards_in_hand.size() >= max_hand_size:
		push_warning("Mano llena, no se puede agregar más cartas")
		return false
	
	var card: CartaHechizo = spell_data.escena.instantiate()
	if card.has_method("setup"):
		card.setup(spell_data)
	else:
		push_error("La escena instanciada no tiene método setup()")
		card.queue_free()
		return false
	
	add_child(card)
	cards_in_hand.append(card)
	
	# Conectar señales
	if not card.card_double_clicked.is_connected(_on_card_double_clicked):
		card.card_double_clicked.connect(_on_card_double_clicked)
	
	# Conectar hover para efectos visuales
	if not card.mouseSobreCarta.is_connected(_on_card_hover):
		card.mouseSobreCarta.connect(_on_card_hover)
	if not card.mouseFueraCarta.is_connected(_on_card_unhover):
		card.mouseFueraCarta.connect(_on_card_unhover)
	
	# Posicionar todas las cartas
	_reposition_cards()
	
	# Animación de entrada
	card.modulate.a = 0
	card.scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.3)
	tween.tween_property(card, "scale", Vector2(card_scale, card_scale), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	return true

func remove_card(card: CartaHechizo) -> SpellCardData:
	if not card or not card.data:
		push_error("Hand: Intento de remover carta inválida")
		return null
		
	var spell_data = card.data as SpellCardData
	cards_in_hand.erase(card)
	
	# Animación de salida
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_property(card, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(card, "position:y", card.position.y - 100, 0.2)
	tween.chain().tween_callback(card.queue_free)
	
	# Reposicionar las cartas restantes
	_reposition_cards()
	
	print("Hand: Carta removida: ", spell_data.name)
	return spell_data

# Posicionar cartas en un arco o línea horizontal
func _reposition_cards():
	var num_cards = cards_in_hand.size()
	if num_cards == 0:
		return
	
	# Calcular ancho total
	var total_width = (num_cards - 1) * card_spacing
	var start_x = -total_width / 2.0
	
	for i in range(num_cards):
		var card = cards_in_hand[i]
		var target_pos = Vector2(start_x + i * card_spacing, 0)
		
		# Animar el movimiento
		var tween = create_tween()
		tween.tween_property(card, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		# Z-index para que las cartas de la derecha estén encima
		card.z_index = i

# Efectos visuales de hover
func _on_card_hover(card: Carta):
	if card not in cards_in_hand:
		return
	emit_signal("mouseEntered", card)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position:y", hover_lift, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(card_scale * 1.1, card_scale * 1.1), 0.2)
	card.z_index = 100  # Traer al frente

func _on_card_unhover():
	# Buscar la carta que ya no tiene hover
	for i in range(cards_in_hand.size()):
		var card = cards_in_hand[i]
		var target_y = 0.0
		
		# Solo resetear si no está seleccionada
		if card != selected_card:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "position:y", target_y, 0.2).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "scale", Vector2(card_scale, card_scale), 0.2)
			card.z_index = i

func _on_card_double_clicked(card: CartaHechizo):
	if not card or not card.data:
		return
		
	var spell_data = card.data as SpellCardData
	if not spell_data:
		push_error("Hand: CartaHechizo sin SpellCardData válido")
		return
	
	print("Hand: Doble click en ", spell_data.name)
	
	var target = null
	
	match spell_data.target_type:
		SpellCardData.TargetType.SELF:
			target = get_tree().get_first_node_in_group("player")
			_cast_spell(card, target)
		SpellCardData.TargetType.ENEMY:
			_start_target_selection(card)

func _start_target_selection(card: CartaHechizo):
	cancel_selection()
	
	selected_card = card
	waiting_for_target = true
	card.highlight(true)
	
	# Activar targets visuales en monstruos
	var monster_grid = get_tree().get_first_node_in_group("MonsterGrid")
	if monster_grid:
		var monsters = monster_grid.get_all_monsters()
		for monster in monsters:
			if monster.can_be_targeted():
				# Agregar efecto visual de "puede ser objetivo"
				monster.modulate = Color(1.5, 1.0, 1.0)
	
	print("Hand: Esperando selección de objetivo...")

func _cast_spell(card: CartaHechizo, target):
	var spell_data = card.data as SpellCardData
	
	print("Hand: Lanzando hechizo: ", spell_data.name)
	emit_signal("card_played", spell_data, target)
	remove_card(card)
	
	cancel_selection()

# Método público para cuando el jugador selecciona un monstruo como objetivo
func target_selected(target: Carta):
	if not waiting_for_target or not selected_card:
		return
		
	print("Hand: Objetivo seleccionado")
	_cast_spell(selected_card, target)

func cancel_selection():
	if selected_card:
		selected_card.highlight(false)
		selected_card = null
	
	waiting_for_target = false
	
	# Desactivar efectos visuales
	var monster_grid = get_tree().get_first_node_in_group("MonsterGrid")
	if monster_grid:
		var monsters = monster_grid.get_all_monsters()
		for monster in monsters:
			monster.modulate = Color.WHITE

func get_hand_size() -> int:
	return cards_in_hand.size()

func is_hand_full() -> bool:
	return cards_in_hand.size() >= max_hand_size

func is_waiting_for_target() -> bool:
	return waiting_for_target

# Debug: Visualizar el área de la mano
func _draw():
	if Engine.is_editor_hint():
		var width = max_hand_size * card_spacing
		var rect = Rect2(-width/2, -50, width, 100)
		draw_rect(rect, Color(0, 1, 1, 0.1), true)
		draw_rect(rect, Color(0, 1, 1), false, 2.0)
