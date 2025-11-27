extends Node2D
class_name Hand

# CONFIGURACIÓN DE GRID
@export var GRID_COLUMNS: int = 1
@export var GRID_ROWS: int = 6
const CELL_WIDTH = 104
const CELL_HEIGHT = 144
const CELL_MARGIN_X = 10
const CELL_MARGIN_Y = 0 

# ESTADO
var grid: Array = []
var max_hand_size: int = GRID_COLUMNS * GRID_ROWS

# Sistema de selección
var selected_spell: CartaHechizo = null
var waiting_for_target: bool = false
var current_target_type: SpellCardData.TargetType

# SEÑALES
signal card_played(spell: SpellCardData, target)
signal hand_full
signal hand_has_space
signal mouseEntered(carta: Carta)
signal spell_selected(spell: CartaHechizo)
signal selection_cancelled

# AUDIO
@onready var spell_cast: AudioStreamPlayer = $SpellCast
@onready var deck_draw: AudioStreamPlayer = $DeckDraw

# ============================================
# INICIALIZACIÓN
# ============================================
func _ready():
	_initialize_grid()
	add_to_group("Hand")

func _initialize_grid():
	grid.resize(GRID_COLUMNS)
	for x in range(GRID_COLUMNS):
		grid[x] = []
		for y in range(GRID_ROWS):
			grid[x].append(null)

# ============================================
# CONVERSIÓN DE COORDENADAS
# ============================================
func grid_to_world(x: int, y: int) -> Vector2:
	var base_pos = Vector2(x * CELL_WIDTH, y * CELL_HEIGHT)
	var margin_offset = Vector2(x * CELL_MARGIN_X, y * CELL_MARGIN_Y)
	return base_pos + margin_offset

func find_empty_slot() -> Vector2i:
	for x in range(GRID_COLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] == null:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

# ============================================
# GESTIÓN DE CARTAS
# ============================================
func add_card(spell_data: SpellCardData) -> bool:
	if is_full():
		push_warning("Hand: Mano llena")
		emit_signal("hand_full")
		return false
	
	var slot = find_empty_slot()
	if slot == Vector2i(-1, -1):
		return false
	
	# Instanciar carta
	var card: CartaHechizo = spell_data.escena.instantiate()
	if not card.has_method("setup"):
		push_error("Hand: Escena sin método setup()")
		card.queue_free()
		return false
	
	card.setup(spell_data)
	add_child(card)
	
	# Posicionar en grid
	card.position = grid_to_world(slot.x, slot.y)
	card.grid_pos = Vector2(slot.x, slot.y)
	card.parent_grid = self
	grid[slot.x][slot.y] = card
	
	# Conectar señales
	_connect_card_signals(card)
	
	# Animación de entrada
	_animate_card_enter(card)
	
	deck_draw.play()
	emit_signal("hand_has_space")
	
	print("Hand: Carta agregada '%s' en [%d,%d]" % [spell_data.name, slot.x, slot.y])
	return true

func remove_card(card: CartaHechizo) -> SpellCardData:
	if not card or not card.data:
		push_error("Hand: Carta inválida")
		return null
	
	var spell_data = card.data as SpellCardData
	var pos = card.grid_pos
	
	# Limpiar grid
	if pos.x >= 0 and pos.x < GRID_COLUMNS and pos.y >= 0 and pos.y < GRID_ROWS:
		grid[int(pos.x)][int(pos.y)] = null
	
	# Animación de salida
	_animate_card_exit(card)
	
	spell_cast.play()
	emit_signal("hand_has_space")
	
	print("Hand: Carta removida '%s'" % spell_data.name)
	return spell_data

# ============================================
# SISTEMA DE SELECCIÓN (DOBLE CLICK)
# ============================================
func _on_card_double_clicked(card: CartaHechizo):
	if not card or not card.data:
		return
	
	var spell_data = card.data as SpellCardData
	
	# Validar si puede lanzarse
	if not card.can_be_cast():
		return
	
	print("Hand: Doble click en '%s' (tipo: %s)" % [spell_data.name, spell_data.get_target_type_string()])
	
	# Determinar flujo según tipo de objetivo
	match spell_data.target_type:
		SpellCardData.TargetType.NONE:
			# Auto-cast inmediato
			_cast_spell(card, null)
		
		SpellCardData.TargetType.SUMMON:
			# Invocar (no requiere selección)
			_cast_spell(card, null)
		
		SpellCardData.TargetType.WEAPON, \
		SpellCardData.TargetType.MONSTER, \
		SpellCardData.TargetType.SPELL_IN_HAND:
			# Iniciar selección de objetivo
			_start_target_selection(card)

# ============================================
# SELECCIÓN DE OBJETIVOS
# ============================================
func _start_target_selection(card: CartaHechizo):
	cancel_selection()
	
	selected_spell = card
	waiting_for_target = true
	current_target_type = card.data.target_type
	
	card.highlight(true)
	_highlight_valid_targets(true)
	
	emit_signal("spell_selected", card)
	
	print("Hand: Esperando selección de objetivo (%s)" % card.data.get_target_type_string())

func target_selected(target):
	if not waiting_for_target or not selected_spell:
		return
	
	# Validar objetivo
	if not selected_spell.data.is_valid_target(target):
		push_warning("Hand: Objetivo inválido")
		return
	
	print("Hand: Objetivo seleccionado")
	_cast_spell(selected_spell, target)

func cancel_selection():
	if selected_spell:
		selected_spell.highlight(false)
		selected_spell = null
	
	waiting_for_target = false
	_highlight_valid_targets(false)
	
	emit_signal("selection_cancelled")

# ============================================
# LANZAR HECHIZO
# ============================================
func _cast_spell(card: CartaHechizo, target):
	var spell_data = card.data as SpellCardData
	
	print("Hand: Lanzando '%s'" % spell_data.name)
	
	# Pagar coste
	card.pay_cost()
	
	# Marcar como usada (estado mutable en la carta)
	card.mark_as_used()
	
	# Emitir señal (Game.gd lo captura)
	emit_signal("card_played", spell_data, target)
	
	# Remover carta
	remove_card(card)
	cancel_selection()

# ============================================
# RESALTADO DE OBJETIVOS
# ============================================
func _highlight_valid_targets(enabled: bool):
	match current_target_type:
		SpellCardData.TargetType.WEAPON:
			_highlight_weapons(enabled)
		SpellCardData.TargetType.MONSTER:
			_highlight_monsters(enabled)
		SpellCardData.TargetType.SPELL_IN_HAND:
			_highlight_spells_in_hand(enabled)

func _highlight_weapons(enabled: bool):
	var player_grid = get_tree().get_first_node_in_group("PlayerWeaponGrid")
	if not player_grid:
		return
	
	for weapon in player_grid.get_all_weapons():
		weapon.modulate = Color(1.0, 1.5, 1.0) if enabled else Color.WHITE


func _highlight_monsters(enabled: bool):
	var monster_grid = get_tree().get_first_node_in_group("MonsterGrid")
	if not monster_grid:
		return
	
	for monster in monster_grid.get_all_monsters():
		if monster.can_be_targeted():
			monster.modulate = Color(1.5, 1.0, 1.0) if enabled else Color.WHITE
		else:
			monster.modulate = Color(0.3, 0.3, 0.3) if enabled else Color.WHITE

func _highlight_spells_in_hand(enabled: bool):
	for x in range(GRID_COLUMNS):
		for y in range(GRID_ROWS):
			var card = grid[x][y]
			if card and card != selected_spell:
				card.modulate = Color(1.0, 1.0, 1.5) if enabled else Color.WHITE

# ============================================
# MANEJO DE INPUT (Click en objetivos)
# ============================================
func _input(event):
	if not waiting_for_target:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_target = _raycast_check_for_target()
		
		if clicked_target:
			target_selected(clicked_target)
		else:
			# Click en área vacía = cancelar
			cancel_selection()

func _raycast_check_for_target():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var collider_parent = result[0].collider.get_parent()
		
		# Verificar tipo según lo que esperamos
		match current_target_type:
			SpellCardData.TargetType.WEAPON:
				if collider_parent is CartaArma:
					return collider_parent
			SpellCardData.TargetType.MONSTER:
				if collider_parent is CartaMonstruo:
					return collider_parent
			SpellCardData.TargetType.SPELL_IN_HAND:
				if collider_parent is CartaHechizo and collider_parent != selected_spell:
					return collider_parent
	
	return null

# ============================================
# CONECTAR SEÑALES
# ============================================
func _connect_card_signals(card: CartaHechizo):
	if not card.card_double_clicked.is_connected(_on_card_double_clicked):
		card.card_double_clicked.connect(_on_card_double_clicked)
	
	if not card.mouseSobreCarta.is_connected(_on_card_hover):
		card.mouseSobreCarta.connect(_on_card_hover)
	
	if not card.mouseFueraCarta.is_connected(_on_card_unhover):
		card.mouseFueraCarta.connect(_on_card_unhover)

# ============================================
# ANIMACIONES
# ============================================
func _animate_card_enter(card: CartaHechizo):
	card.modulate.a = 0
	card.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.3)
	tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _animate_card_exit(card: CartaHechizo):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_property(card, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(card, "position:y", card.position.y - 100, 0.2)
	tween.chain().tween_callback(card.queue_free)

# ============================================
# EFECTOS DE HOVER
# ============================================
func _on_card_hover(card: Carta):
	if card not in get_all_cards():
		return
	
	emit_signal("mouseEntered", card)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position:y",card.position.y - 20, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.2)
	card.z_index = 100

func _on_card_unhover():
	for card in get_all_cards():
		if card != selected_spell:
			var original_pos = grid_to_world(int(card.grid_pos.x), int(card.grid_pos.y))
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(card, "position", original_pos, 0.2).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "scale", Vector2.ONE, 0.2)
			card.z_index = 0

# ============================================
# UTILIDADES
# ============================================
func get_all_cards() -> Array:
	var cards = []
	for x in range(GRID_COLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] != null:
				cards.append(grid[x][y])
	return cards

func get_hand_size() -> int:
	return get_all_cards().size()

func is_full() -> bool:
	return get_hand_size() >= max_hand_size

func is_waiting_for_target() -> bool:
	return waiting_for_target

func get_card_at(x: int, y: int) -> CartaHechizo:
	if x < 0 or x >= GRID_COLUMNS or y < 0 or y >= GRID_ROWS:
		return null
	return grid[x][y]
