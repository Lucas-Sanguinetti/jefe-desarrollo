extends Node2D
class_name WeaponGrid

const GRID_COLLUMNS = 2        # 4x4
const GRID_ROWS = 3
const CELL_SIZE = 64       # ancho/alto de cada celda (en píxeles)
const CellHeigth = 144     
const CellWeigth = 104

var grid = []  # array 2D de referencias a fichas

signal carta_Clickeada (carta:Carta)

func _ready():
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
	
	if cardPiece.has_signal("card_double_clicked"):
		cardPiece.card_double_clicked.connect(_on_weapon_double_clicked)
	
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

func get_all_weapons() -> Array:
	var weapons = []
	for x in range(GRID_COLLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] != null:
				weapons.append(grid[x][y])
	return weapons

# Para agarrar un arma particular
func take_weapon(x: int, y: int):
	var weapon = grid[x][y]
	grid[x][y] = null
	return weapon

func _on_weapon_double_clicked(carta: Carta):
	print("WeaponGrid: Arma con doble click en posición ", carta.grid_pos)
	# Notificar al WeaponManager
	emit_signal("carta_Clickeada",carta)
