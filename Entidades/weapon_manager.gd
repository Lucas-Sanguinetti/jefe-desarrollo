extends Node
class_name WeaponManager

# Referencias a los grids
var weapon_grid: WeaponGrid = null  # "Almacén"
var player_grid: PlayerWeaponGrid = null  # "Equipadas"

# Armas iniciales que el jugador comienza equipadas
@export var initial_equipped_weapons: Array[WeaponCardData] = []

func _ready():
	# Buscar los grids en la escena
	call_deferred("initialize_grids")

func initialize_grids():
	# Buscar WeaponGrid
	var weapon_spawner = get_node_or_null("../WeaponSpawner")
	if weapon_spawner:
		weapon_grid = weapon_spawner.get_node_or_null("WeaponGrid")
	
	# Buscar PlayerWeaponGrid
	var player_spawner = get_node_or_null("../PlayerWeaponSpawner")
	if player_spawner:
		player_grid = player_spawner.get_node_or_null("PlayerWeaponGrid")
	
	if not weapon_grid:
		push_warning("WeaponManager: No se encontró WeaponGrid")
	if not player_grid:
		push_warning("WeaponManager: No se encontró PlayerWeaponGrid")
	
	# Equipar armas iniciales
	equip_initial_weapons()

# Equipar armas iniciales predefinidas
func equip_initial_weapons():
	if not player_grid:
		return
	
	for weapon_data in initial_equipped_weapons:
		if weapon_data and weapon_data is WeaponCardData:
			player_grid.create_and_equip_weapon(weapon_data)
			print("Arma inicial equipada: ", weapon_data.escena)

# Mover un arma del WeaponGrid al PlayerWeaponGrid
func transfer_weapon_to_player(from_x: int, from_y: int) -> bool:
	if not weapon_grid or not player_grid:
		push_warning("WeaponManager: Grids no inicializados")
		return false
	
	# Verificar si hay espacio
	if player_grid.is_full():
		print("WeaponManager: PlayerWeaponGrid está lleno")
		return false
	
	# Tomar arma del almacén
	var weapon = weapon_grid.take_weapon(from_x, from_y)
	if not weapon:
		print("WeaponManager: No hay arma en la posición indicada")
		return false
	
	# Equipar en el grid del jugador
	var success = player_grid.equip_weapon(weapon)
	
	if not success:
		# Si falló, devolver al almacén
		push_warning("WeaponManager: No se pudo equipar el arma")
		# Aquí podrías re-agregarlo al WeaponGrid si lo deseas
		weapon.queue_free()
		return false
	
	print("WeaponManager: Arma transferida exitosamente")
	return true

# Mover un arma del PlayerWeaponGrid de vuelta al WeaponGrid
func return_weapon_to_storage(from_x: int, from_y: int) -> bool:
	if not weapon_grid or not player_grid:
		return false
	
	# Verificar si hay espacio en el almacén
	if weapon_grid.get_empty_slots_count() <= 0:
		print("WeaponManager: WeaponGrid está lleno")
		return false
	
	# Desequipar del jugador
	var weapon = player_grid.unequip_weapon(from_x, from_y)
	if not weapon:
		return false
	
	# Agregar al almacén
	var weapon_data = weapon.data as WeaponCardData
	weapon.queue_free()  # Destruir la instancia vieja
	weapon_grid.invoke_random_piece(weapon_data)  # Crear nueva en el almacén
	
	print("WeaponManager: Arma devuelta al almacén")
	return true

# Función útil para debug: transferir arma al azar
func transfer_random_weapon_to_player() -> bool:
	if not weapon_grid:
		return false
	
	var available_weapons = weapon_grid.get_all_available_weapons()
	if available_weapons.is_empty():
		print("WeaponManager: No hay armas disponibles en el almacén")
		return false
	
	var random_weapon = available_weapons[randi() % available_weapons.size()]
	var pos = random_weapon.grid_pos
	
	return transfer_weapon_to_player(int(pos.x), int(pos.y))
