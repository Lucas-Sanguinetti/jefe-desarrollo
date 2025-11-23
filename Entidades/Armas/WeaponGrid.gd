extends Node2D
class_name WeaponGrid

@export var GRID_COLLUMNS = 2 
@export var GRID_ROWS = 3
const CellHeigth = 144     
const CellWeigth = 104

var grid = []  # array 2D de referencias a fichas
var armas_por_celda := {} # Diccionario: Vector2i -> CartaArma
signal mouseEntered(carta: Carta)
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
	
func _conectUp(carta: Carta): 
	emit_signal("mouseEntered", carta)

# Colocar ficha en una posición lógica
func place_piece(x: int, y: int, cardData: WeaponCardData) -> bool:
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
	registrar_arma(cardPiece,Vector2i(x,y))
	
	if cardPiece.has_signal("card_double_clicked"):
		cardPiece.card_double_clicked.connect(_on_weapon_double_clicked)
	
	return true
	
#Buscar una celda libre al azar e invocar allí
func invoke_random_piece(carta: WeaponCardData):
	var empty_cells = get_empty_slots()
	if empty_cells.is_empty():
		print("No hay más espacios")
		return

	var pos = empty_cells[randi() % empty_cells.size()]
	place_piece(pos.x, pos.y, carta)

# Para agarrar un arma particular
func take_weapon(x: int, y: int):
	var weapon = grid[x][y]
	grid[x][y] = null
	return weapon

func _on_weapon_double_clicked(carta: Carta):
	print("WeaponGrid: Arma con doble click en posición ", carta.grid_pos)
	# Notificar al WeaponManager
	emit_signal("carta_Clickeada",carta)

func get_empty_slots() -> Array:
	var empty_cells = []
	for x in range(GRID_COLLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] == null:
				empty_cells.append(Vector2(x, y))
	return empty_cells

func get_all_weapons() -> Array:
	var weapons = []
	for x in range(GRID_COLLUMNS):
		for y in range(GRID_ROWS):
			if grid[x][y] != null:
				weapons.append(grid[x][y])
	return weapons
	
func registrar_arma(arma: CartaArma, celda:Vector2i):
	armas_por_celda[celda] = arma

func obtener_arma_en(celda:Vector2i) -> CartaArma:
	return armas_por_celda.get(celda,null)

func verificar_saldo_suficiente(x: int, y: int) -> bool:
	var arma = obtener_arma_en(Vector2i(x,y))
	return arma.nivel <= MoneyManager.get_money()
	
