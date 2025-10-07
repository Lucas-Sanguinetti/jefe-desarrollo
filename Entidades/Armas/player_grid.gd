extends Node2D
class_name PlayerWeaponGrid

const GRID_COLUMNS = 5
const GRID_ROWS = 1
const CELL_HEIGHT = 144
const CELL_WIDTH = 104
const CELL_MARGIN_X = 38  # Margen horizontal entre celdas 
const CELL_MARGIN_Y = 0  # Margen vertical entre celdas 

var grid = []  # array 2D de referencias a cartas
var card_manager: Node2D = null
var max_capacity: int = GRID_COLUMNS * GRID_ROWS

signal weapon_equipped(weapon: Carta)
signal weapon_removed(weapon: Carta)
signal grid_full
signal grid_has_space

func _ready():
	grid.resize(GRID_COLUMNS)
	for x in range(GRID_COLUMNS):
		grid[x] = []
		for y in range(GRID_ROWS):
			grid[x].append(null)
	
	# Buscar el CardManager en la escena
	card_manager = get_node_or_null("/root/Main/CardManager")
	if not card_manager:
		push_warning("No se encontró CardManager en la escena")#Debug


# Convierte posición lógica (x,y) en coordenada de pantalla
func grid_to_world(x: int, y: int) -> Vector2:
	# Calcula la posición base
	var base_pos = Vector2(x * CELL_WIDTH, y * CELL_HEIGHT)
	# Agrega el margen acumulado según la posición
	var margin_offset = Vector2(x * CELL_MARGIN_X, y * CELL_MARGIN_Y)
	return base_pos + margin_offset


# Equipar un arma EXISTENTE (instancia de Carta)
func equip_weapon(weapon: Carta, x: int = -1, y: int = -1) -> bool:
	if not weapon or not weapon.data is WeaponCardData:
		push_warning("Solo se pueden equipar armas (WeaponCardData)")
		return false
	
	# Si no se especifica posición, buscar una libre
	if x == -1 or y == -1:
		var empty_pos = find_empty_slot()
		if empty_pos == Vector2(-1, -1):
			print("PlayerWeaponGrid: Grid lleno, no se puede equipar arma")
			emit_signal("grid_full")
			return false
		x = int(empty_pos.x)
		y = int(empty_pos.y)
	
	if not is_valid_position(x, y) or grid[x][y] != null:
		return false
	
	# Re-parentear el arma a este grid
	var old_parent = weapon.get_parent()
	if old_parent:
		old_parent.remove_child(weapon)
	
	add_child(weapon)
	
	# Actualizar posición y referencias
	weapon.position = grid_to_world(x, y)
	weapon.grid_pos = Vector2(x, y)
	weapon.parent_grid = self
	grid[x][y] = weapon
	
	#if card_manager:
		#if not weapon.mouseSobreCarta.is_connected(card_manager.on_hovered_over_card):
			#card_manager.connect_card_signals(weapon)
		#if not weapon.card_selected_for_attack.is_connected(card_manager._on_card_selected_for_attack):
			#card_manager.connect_combat_signals(weapon)
	
	# Habilitar combate para esta arma
	weapon.can_attack = true
	weapon.set_card_state(Carta.CardState.NORMAL)
	
	emit_signal("weapon_equipped", weapon)
	
	if get_empty_slots_count() > 0:
		emit_signal("grid_has_space")
	
	print("Arma equipada en PlayerWeaponGrid: ", weapon.name)
	return true

#Crear arma desde CardData
func create_and_equip_weapon(cardData: WeaponCardData, x: int = -1, y: int = -1) -> bool:
	var weapon = cardData.escena.instantiate()
	if weapon.has_method("setup"):
		weapon.setup(cardData)
	
	return equip_weapon(weapon, x, y)

# Desequipar un arma (retornarla al WeaponGrid u otro lugar)
func unequip_weapon(x: int, y: int) -> Carta:
	if not is_valid_position(x, y) or grid[x][y] == null:
		return null
	
	var weapon = grid[x][y]
	grid[x][y] = null
	
	# Desconectar del grid pero NO destruir la carta
	remove_child(weapon)
	weapon.parent_grid = null
	weapon.grid_pos = Vector2(-1, -1)
	
	emit_signal("weapon_removed", weapon)
	emit_signal("grid_has_space")
	
	print("Arma desequipada de PlayerWeaponGrid: ", weapon.name)
	return weapon

# Buscar primera celda libre
func find_empty_slot() -> Vector2:
	for x in range(GRID_COLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] == null:
				return Vector2(x, y)
	return Vector2(-1, -1)

# Obtener todas las armas equipadas
func get_all_weapons() -> Array:
	var weapons = []
	for x in range(GRID_COLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] != null:
				weapons.append(grid[x][y])
	return weapons

# Resetear todas las armas (al inicio del turno)
func reset_all_weapons():
	var weapons = get_all_weapons()
	print("PlayerWeaponGrid: Reseteando ", weapons.size(), " armas")#Debug
	for weapon in weapons:
		if weapon.has_method("reset_attack_ability"):
			weapon.reset_attack_ability()
	print("PlayerWeaponGrid: Reset completado")#Debug

# Bloquear todas las armas
func block_all_weapons():
	var weapons = get_all_weapons()
	print("PlayerWeaponGrid: Bloqueando ", weapons.size(), " armas")#Debug
	for weapon in weapons:
		if weapon.has_method("block_attack_ability"):
			weapon.block_attack_ability()
	print("PlayerWeaponGrid: Bloqueo completado")#Debug

func is_valid_position(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_COLUMNS and y >= 0 and y < GRID_ROWS

func get_empty_slots_count() -> int:
	var count = 0
	for x in range(GRID_COLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] == null:
				count += 1
	return count

# Verificar si el grid está lleno
func is_full() -> bool:
	return get_empty_slots_count() == 0

# Debug: Visualizar las celdas
func _draw():
	if Engine.is_editor_hint():
		for x in range(GRID_COLUMNS):
			for y in range(GRID_ROWS):
				var rect = Rect2(Vector2(x, y) * Vector2(CELL_WIDTH, CELL_HEIGHT), Vector2(CELL_WIDTH, CELL_HEIGHT))
				draw_rect(rect, Color(0, 1, 0, 0.1), true)
				draw_rect(rect, Color(0, 1, 0), false, 2.0)
