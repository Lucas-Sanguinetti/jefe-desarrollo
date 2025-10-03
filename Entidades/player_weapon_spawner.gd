extends Node2D

@onready var player_grid: PlayerWeaponGrid = $PlayerGrid
@onready var turn_button = get_node_or_null("../CanvasLayer/PasarTurno")

@export var initial_weapons: Array[WeaponCardData] = []

func _ready():
	if player_grid:
		player_grid.weapon_equipped.connect(_on_weapon_equipped)
		player_grid.weapon_removed.connect(_on_weapon_removed)
		player_grid.grid_full.connect(_on_grid_full)
		player_grid.grid_has_space.connect(_on_grid_has_space)
	
	initial_load()

func initial_load():
	# Opción 1: Usar armas predefinidas en el export
	if not initial_weapons.is_empty():
		print("Cargando armas iniciales predefinidas...") #Debug
		for weapon_data in initial_weapons:
			if weapon_data:
				player_grid.create_and_equip_weapon(weapon_data)
	else:
		#Si no hay predefinidas, no cargar nada?
		print("No hay armas iniciales. El jugador debe equipar armas manualmente.")#Debug

# Callbacks de señales
func _on_weapon_equipped(weapon: Carta):
	print("Arma equipada en el grid del jugador: ", weapon.name)

func _on_weapon_removed(weapon: Carta):
	print("Arma removida del grid del jugador: ", weapon.name)

func _on_grid_full():
	print("PlayerWeaponGrid está lleno!")

func _on_grid_has_space():
	print("PlayerWeaponGrid tiene espacio disponible")


func reset_weapons_for_new_turn():
	if player_grid:
		player_grid.reset_all_weapons()


func block_weapons():
	if player_grid:
		player_grid.block_all_weapons()

# Para futura eleccion de arma
func equip_weapon(weapon: Carta) -> bool:
	if player_grid:
		return player_grid.equip_weapon(weapon)
	return false
