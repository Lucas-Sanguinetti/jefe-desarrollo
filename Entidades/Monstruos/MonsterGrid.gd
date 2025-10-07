extends Node2D
class_name MonsterGrid

const GRID_SIZE = 4        # 4x4
const CELL_SIZE = 64       # ancho/alto de cada celda (en píxeles)
const CellHeigth = 144     
const CellWeigth = 104

var grid = []  # array 2D de referencias a fichas
signal mouseEntered(carta: Carta)

signal monster_died(monster: Carta)

func _ready():
	# Inicializar grilla vacía
	grid.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		grid[x] = []
		for y in range(GRID_SIZE):
			grid[x].append(null)

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
	#Deberia corroborarlo como buena practica?
	grid[int(pos.x)][int(pos.y)] = null
	
	emit_signal("monster_died",monster)
	pass

#funcion puramente para visualizar las celdas y el espaciado
#func _draw():
	#for x in range(GRID_SIZE):
		#for y in range(GRID_SIZE):
			#var rect = Rect2(Vector2(x, y) * Vector2(CellWeigth, CellHeigth), Vector2(CellWeigth, CellHeigth))
			#draw_rect(rect, Color(1, 1, 1, 0.1), true)   # relleno semitransparente
			#draw_rect(rect, Color(1, 1, 1), false, 2.0) # borde blanco
