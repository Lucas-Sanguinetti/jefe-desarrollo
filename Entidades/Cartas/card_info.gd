extends Node2D

#esto no es una carta, es un nodo para mostrar la carta
@onready var label: Label = $Label

const GRID_SIZE = 1
const CellHeigth = 432    
const CellWeigth = 312   

var weapon_grid
var player_grid
var monster_grid
var hand
var cartaNueva: Carta
var grid = [] 

# Called when the node enters the scene tree for the first time.
func _ready():
	# Inicializar grilla vacía
	grid.resize(GRID_SIZE)
	for x in range(GRID_SIZE):
		grid[x] = []
		for y in range(GRID_SIZE):
			grid[x].append(null)
	
			
	# Buscar WeaponGrid
	var weapon_spawner = get_node("../WeaponSpawner")
	if weapon_spawner:
		weapon_grid = weapon_spawner.get_node_or_null("WeaponGrid")
	
	# Buscar PlayerWeaponGrid
	var player_spawner = get_node_or_null("../PlayerWeaponSpawner")
	if player_spawner:
		player_grid = player_spawner.get_node_or_null("PlayerGrid")
		
	# Buscar PlayerWeaponGrid
	var monster_spawner = get_node_or_null("../MonsterSpawner")
	if monster_spawner:
		monster_grid = monster_spawner.get_node_or_null("MonsterGrid")
	
	hand = get_node_or_null("../PlayerSpells")
	
	# Buscar PlayerWeaponGrid
	if not weapon_grid:
		push_warning("WeaponManager: No se encontró WeaponGrid")
	if not player_grid:
		push_warning("WeaponManager: No se encontró PlayerWeaponGrid")
	if not monster_grid:
		push_warning("WeaponManager: No se encontró MonsterGrid")
	if not hand:
		push_warning("CardInfo: No se encontró Hand")
	
	monster_grid.mouseEntered.connect(_show_card)
	player_grid.mouseEntered.connect(_show_card)
	weapon_grid.mouseEntered.connect(_show_card)
	if hand:
		hand.mouseEntered.connect(_show_card)
	label.hide()
	#equip_initial_weapons()
	
# Convierte posición lógica (x,y) en coordenada de pantalla
func grid_to_world(x: int, y: int) -> Vector2:
	return Vector2(x, y) * Vector2(CellWeigth, CellHeigth)	
	
# Colocar ficha en una posición lógica
func place_piece(x: int, y: int, card: Carta) -> bool:
	add_child(card)
	card.position = grid_to_world(x, y)
	card.grid_pos = Vector2(x, y)
	grid[x][y] = card
	return true


func _show_card(carta: Carta):
	_clear_preview()
	var display_resource = carta.get_display_resource()
	cartaNueva = display_resource.escena.instantiate()
	cartaNueva.setup(display_resource)
	cartaNueva.scale = Vector2(3, 3)
	place_piece(0, 0, cartaNueva)
	carta.actLabel(label)
	label.show()

func _clear_preview():
	if cartaNueva and is_instance_valid(cartaNueva):
		cartaNueva.queue_free()
		cartaNueva = null
	if grid[0][0] != null:
		grid[0][0] = null
	label.hide()
