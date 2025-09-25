extends Node2D

const GRID_SIZE = 4        # 4x4
const CELL_SIZE = 64       # ancho/alto de cada celda (en píxeles)
@export var ficha_scene: PackedScene

var grid = []  # array 2D de referencias a fichas

func _ready():
	# Inicializar grilla vacía
	grid.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		grid[x] = []
		for y in range(GRID_SIZE):
			grid[x].append(null)
	_draw()

	## Ejemplo: invocar 5 fichas al azar al empezar
	#for i in range(5):
		#invoke_random_piece()

# Convierte posición lógica (x,y) en coordenada de pantalla
func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(x, y) * CELL_SIZE

# Colocar ficha en una posición lógica
#func place_piece(x: int, y: int) -> bool:
	#if grid[x][y] != null:
		#return false  # ya ocupado
	#var piece = ficha_scene.instantiate()
	#add_child(piece)
	#piece.position = grid_to_world(x, y)
	#piece.grid_pos = Vector2(x, y)
	#grid[x][y] = piece
	#return true
	

# Buscar una celda libre al azar e invocar allí
#func invoke_random_piece():
	#var empty_cells = []
	#for x in range(GRID_SIZE):
		#for y in range(GRID_SIZE):
			#if grid[x][y] == null:
				#empty_cells.append(Vector2(x, y))
#
	#if empty_cells.is_empty():
		#print("No hay más espacios")
		#return
#
	#var pos = empty_cells[randi() % empty_cells.size()]
	#place_piece(pos.x, pos.y)

#funcion puramente para visualizar las celdas y el espaciado
func _draw():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var rect = Rect2(Vector2(x, y) * CELL_SIZE, Vector2(CELL_SIZE, CELL_SIZE))
			draw_rect(rect, Color(1, 1, 1, 0.1), true)   # relleno semitransparente
			draw_rect(rect, Color(1, 1, 1), false, 2.0) # borde blanco
