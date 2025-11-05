extends Node
class_name WeaponManager

var weapon_grid: WeaponGrid = null  # "Almacén"
var player_grid: PlayerWeaponGrid = null  # "Equipadas"
var monster_grid: MonsterGrid = null

@onready var blacksmith: AudioStreamPlayer = $Blacksmith

@export var initial_equipped_weapons: Array[WeaponCardData] = []

var limiteArmasTurno: int = 99
var armasTransferidas:int = 0
var monstruoMurio: bool = false

signal armaTransferida

func _ready():
	# Buscar los grids en la escena

	call_deferred("initialize_grids")
	

func initialize_grids():
	# Buscar WeaponGrid
	var weapon_spawner = get_node("../WeaponSpawner")#get_node_or_null("/WeaponSpawner")
	if weapon_spawner:
		weapon_grid = weapon_spawner.get_node_or_null("WeaponGrid")
	
	# Buscar PlayerWeaponGrid
	var player_spawner = get_node_or_null("../PlayerWeaponSpawner")
	if player_spawner:
		player_grid = player_spawner.get_node_or_null("PlayerGrid")
		
	var monster_spawner = get_node_or_null("../MonsterSpawner")
	if monster_spawner:
		monster_grid = monster_spawner.get_node_or_null("MonsterGrid")
	
	if not weapon_grid:
		push_warning("WeaponManager: No se encontró WeaponGrid")
	if not player_grid:
		push_warning("WeaponManager: No se encontró PlayerWeaponGrid")
	if not monster_grid:
		push_warning("WeaponManager: No se encontró MonsterGrid")
	
	weapon_grid.carta_Clickeada.connect(_on_carta_clikeada)
	monster_grid.monster_died.connect(_on_monster_die)
	
	#equip_initial_weapons()

@warning_ignore("unused_parameter") #para proximas mejoras en el sistema
func _on_monster_die(monster: Carta):
	monstruoMurio = true
	pass

# Metodo alternativo de armas iniciales
func equip_initial_weapons():
	if not player_grid:
		return
	
	for weapon_data in initial_equipped_weapons:
		if weapon_data and weapon_data is WeaponCardData:
			player_grid.create_and_equip_weapon(weapon_data)
			print("Arma inicial equipada: ", weapon_data.escena)

# Mover un arma del WeaponGrid al PlayerWeaponGrid
func transfer_weapon_to_player(from_x: int, from_y: int) -> bool:
	
	if !verificar_transferencia(from_x, from_y):
		return false
	
	# Tomar arma del almacén
	var weapon = weapon_grid.take_weapon(from_x, from_y)
	if not weapon:
		print("WeaponManager: No hay arma en la posición indicada") #Debug
		return false
	
	# Equipar en el grid del jugador
	var success = player_grid.equip_weapon(weapon)
	blacksmith.play()
	
	if not success:
		# Si falló, devolver al almacén
		push_warning("WeaponManager: No se pudo equipar el arma") #Debug
		# Agregar al weapon grid / devolver al lugar de donde la saque
		weapon.queue_free()
		return false
	
	# Reducir monedas
	var arma = weapon_grid.obtener_arma_en(Vector2i(from_x,from_y))
	MoneyManager.perderMonedas(arma.nivel)
	
	print("WeaponManager: Arma transferida exitosamente")
	armasTransferidas += 1
	emit_signal("armaTransferida")
	return true

# Modificar para deck segun decision empresarial
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
	
	print("WeaponManager: Arma devuelta al almacén")  #Debug
	return true

# Debug para agregar arma
func venderArma(carta:CartaArma):
	if not weapon_grid or not player_grid:
		return false
	
	var postion = carta.grid_pos
	
	# Desequipar del jugador
	var weapon = player_grid.unequip_weapon(postion.x, postion.y)
	if not weapon:
		return false

func verificar_transferencia(from_x: int, from_y: int) -> bool:
	#Verificar monstruo derrotado
	#if !monstruoMurio:
		#push_warning("WeaponManager: No se mato ningun monstruo") #Debug
		#return false
	#Verificar cantidad de armas transferidas
	if armasTransferidas >= limiteArmasTurno:
		print("WeaponManager: No se pueden agarrar mas de: "+str(limiteArmasTurno)+" armas por turno") #Debug
		return false
	
	# Verificar si hay espacio
	if player_grid.is_full():
		print("WeaponManager: PlayerWeaponGrid está lleno") #Debug
		return false
	
	#Verificar armas disponibles
	var available_weapons = weapon_grid.get_all_weapons()
	if available_weapons.is_empty():
		print("WeaponManager: No hay armas disponibles en el almacén")  #Debug
		return false
	
	var validacion_final:bool = weapon_grid.verificar_saldo_suficiente(from_x,from_y)

	return validacion_final

func reset_turn():
	armasTransferidas = 0
	monstruoMurio = false
	pass

func _on_carta_clikeada(carta:Carta):

	var postion = carta.grid_pos
	var success = transfer_weapon_to_player(postion.x, postion.y)
	
	if success:
		print("WeaponManager: Arma equipada exitosamente mediante doble click")
	else:
		print("WeaponManager: Fallo al equipar arma mediante doble click")
