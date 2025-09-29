extends Node2D

const GRID_COLLUMNS = 2        # 4x4
const GRID_ROWS = 3
const CELL_SIZE = 64       # ancho/alto de cada celda (en píxeles)
const CellHeigth = 144     
const CellWeigth = 104
@export var ficha_scene: PackedScene

var grid = []  # array 2D de referencias a fichas

func _ready():
	# Inicializar grilla vacía
	grid.resize(GRID_COLLUMNS * GRID_ROWS )
	for x in range(GRID_COLLUMNS):
		grid[x] = []
		for y in range(GRID_ROWS):
			grid[x].append(null)

# Convierte posición lógica (x,y) en coordenada de pantalla
func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(x, y) * Vector2(CellWeigth, CellHeigth)

# Colocar ficha en una posición lógica
func place_piece(x: int, y: int, cardData: WeaponCardData) -> bool:
	if grid[x][y] != null:
		return false  # ya ocupado
	
	# Setup con los datos de la carta
	
	var cardPiece = cardData.escena.instantiate()
	if cardPiece.has_method("setup"):
		cardPiece.setup(cardData)
	add_child(cardPiece)
	
	cardPiece.position = grid_to_world(x, y)
	cardPiece.grid_pos = Vector2(x, y)
	grid[x][y] = cardPiece
	return true
	

#Buscar una celda libre al azar e invocar allí
func invoke_random_piece(carta: WeaponCardData):
	var empty_cells = []
	for x in range(GRID_COLLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] == null:
				empty_cells.append(Vector2(x, y))

	if empty_cells.is_empty():
		print("No hay más espacios")
		return

	var pos = empty_cells[randi() % empty_cells.size()]
	place_piece(pos.x, pos.y, carta)
