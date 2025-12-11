extends Node2D
class_name MonsterGrid

@export var GRID_SIZE = 4        # 4x4
const CELL_SIZE = 64       # ancho/alto de cada celda (en píxeles)
const CellHeigth = 144     
const CellWeigth = 104

var grid = []  # array 2D de referencias a fichas

@onready var visuals: MonsterGridVisuals = $MonsterGridVisuals

signal mouseEntered(carta: Carta)
signal monster_died(monster: Carta)
signal boss_died()


func _ready():
	# Inicializar grilla vacía
	grid.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		grid[x] = []
		for y in range(GRID_SIZE):
			grid[x].append(null)
	visuals.update_valiente_overlays()
	visuals.update_escurridizo_overlays()
	add_to_group("MonsterGrid")

# Convierte posición lógica (x,y) en coordenada de pantalla
func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(x, y) * Vector2(CellWeigth, CellHeigth)

# Colocar ficha en una posición lógica
func place_piece(x: int, y: int, cardData: MonsterCardData) -> bool:
	if grid[x][y] != null:
		return false  # ya ocupado
	
	# Setup con los datos de la carta
	
	var cardPiece = cardData.escena.instantiate()
	if cardPiece.has_method("setup"):
		cardPiece.setup(cardData)
	add_child(cardPiece)

	cardPiece.mouseSobreCarta.connect(Callable(self, "_conectUp"))

	cardPiece.position = grid_to_world(x, y)
	cardPiece.grid_pos = Vector2(x, y)
	grid[x][y] = cardPiece
	cardPiece.card_died.connect(_on_monster_died.bind(cardPiece))
	
	cardPiece.boss_died.connect(_on_boss_died)
	
	var card_manager = get_tree().get_first_node_in_group("CardManager")
	if card_manager and card_manager.has_method("connect_card_signals"):
		card_manager.connect_card_signals(cardPiece)
	
	visuals.update_escurridizo_overlays()
	visuals.update_valiente_overlays()
	
	return true

func _conectUp(carta: Carta):
	emit_signal("mouseEntered", carta)
	

#Buscar una celda libre al azar e invocar allí
func invoke_random_piece(carta: MonsterCardData):
	var empty_cells = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == null:
				empty_cells.append(Vector2(x, y))

	if empty_cells.is_empty():
		print("No hay más espacios")
		return

	var pos = empty_cells[randi() % empty_cells.size()]
	place_piece(pos.x, pos.y, carta)

func _on_monster_died(monster: Carta):
	var pos = monster.grid_pos
	grid[int(pos.x)][int(pos.y)] = null
	
	emit_signal("monster_died",monster)
	visuals.update_escurridizo_overlays()
	visuals.update_valiente_overlays()

func _on_boss_died():
	emit_signal("boss_died")

func get_all_monsters() -> Array:
	var monsters = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] != null:
				monsters.append(grid[x][y])
	return monsters

func reset_all_monster_traits():
	var monsters = get_all_monsters()
	for monster in monsters:
		monster.reset_traits_for_new_turn()

func get_empty_cells() -> Array:
	var empty = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == null:
				empty.append(Vector2(x, y))
	return empty

@warning_ignore("shadowed_variable_base_class")
func _spawn_from_renacer(position: Vector2, monster_data: MonsterCardData):
	var x = int(position.x)
	var y = int(position.y)
	
	# Verificar que la celda esté vacía
	if grid[x][y] != null:
		push_warning("Renacer: La celda [%d,%d] no está vacía todavía" % [x, y])
		# Reintentar en el siguiente frame
		call_deferred("_spawn_from_renacer", position, monster_data)
		return
	
	# Invocar el nuevo monstruo
	var success = place_piece(x, y, monster_data)
	
	if success:
		print("Renacer: Monstruo invocado en [%d,%d] con %d HP" % [x, y, monster_data.hp])
		
		# Mostrar efecto de spawn
		if visuals:
			var spawned_card = grid[x][y]
			visuals.show_spawn_effect(position, spawned_card)
	else:
		push_error("Renacer: Falló al invocar monstruo en [%d,%d]" % [x, y])
