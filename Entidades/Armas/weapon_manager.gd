extends Node
class_name WeaponManager

var weapon_grid: WeaponGrid = null  # "Almacén"
var player_grid: PlayerWeaponGrid = null  # "Equipadas"
var monster_grid: MonsterGrid = null
var weapon_spawner = null


@onready var blacksmith: AudioStreamPlayer = $Blacksmith

var limiteArmasTurno: int = 99
var armasTransferidas:int = 0
var monstruoMurio: bool = false

signal armaTransferida

func _ready():
	call_deferred("initialize_grids")
	add_to_group("WeaponManager")

func initialize_grids():
	#var parent = get_parent()
	#if parent is Tutorial:
		#weapon_spawner = get_node("../WeaponSpawner")
		#if weapon_spawner:
			#weapon_grid = weapon_spawner.get_node_or_null("WeaponGrid")
	#else:
		## Buscar WeaponGrid
	weapon_spawner = get_node("../WeaponSpawner")
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
	

@warning_ignore("unused_parameter") #para proximas mejoras en el sistema
func _on_monster_die(monster: Carta):
	monstruoMurio = true
	pass

# Mover un arma del WeaponGrid al PlayerWeaponGrid
func transfer_weapon_to_player(from_x: int, from_y: int) -> bool:
	if !verificar_transferencia(from_x, from_y):
		return false
	var arma_nivel = weapon_grid.obtener_arma_en(Vector2i(from_x, from_y)).nivel
	# Tomar arma del almacén
	var weapon = weapon_grid.take_weapon(from_x, from_y)
	if not weapon:
		return false
	
	# Equipar en el grid del jugador
	var success = player_grid.equip_weapon(weapon)
	blacksmith.play()
	
	if not success:
		# Si falló, devolver al almacén
		weapon.queue_free()
		return false
	
	# Reducir monedas
	MoneyManager.perderMonedas(arma_nivel)
	
	# Marcar como comprada en este turno
	weapon.mark_as_purchased()
	
	print("WeaponManager: Arma transferida exitosamente")
	armasTransferidas += 1
	emit_signal("armaTransferida")
	return true

# AGREGAR esta función en WeaponManager.gd

# Devuelve todas las armas de la tienda al mazo y genera nuevas
func reroll_shop_weapons() -> bool:
	if not weapon_grid:
		push_error("WeaponManager: No hay WeaponGrid disponible")
		return false
	
	print("WeaponManager: Iniciando reroll de tienda...")
	
	# 1. Obtener todas las armas actuales en el grid
	var weapons_to_return = []
	for x in range(weapon_grid.GRID_COLLUMNS):
		for y in range(weapon_grid.GRID_ROWS):
			if weapon_grid.grid[x][y] != null:
				var weapon = weapon_grid.grid[x][y]
				weapons_to_return.append(weapon)
	
	print("WeaponManager: Encontradas %d armas en tienda" % weapons_to_return.size())
	
	# 2. Devolver cada arma al mazo
	for weapon in weapons_to_return:
		var weapon_data = weapon.data as WeaponCardData
		if weapon_data:
			# Devolver la carta al mazo
			WeaponDeck.return_card_to_deck(weapon_data)
			print("  → Devuelta: %s" % weapon_data.name)
		
		# Limpiar la posición en el grid
		var pos = weapon.grid_pos
		if pos.x >= 0 and pos.y >= 0:
			weapon_grid.grid[int(pos.x)][int(pos.y)] = null
		
		# Destruir la instancia visual
		weapon.queue_free()
	
	# 3. Esperar un frame para que se liberen los nodos
	await get_tree().process_frame
	
	# 4. Mezclar el mazo para que salgan cartas diferentes
	WeaponDeck.shuffle_deck()
	
	# 5. Generar nuevas armas en la tienda
	if weapon_spawner and weapon_spawner.has_method("turn_loader"):
		weapon_spawner.turn_loader()
		print("WeaponManager: ✅ Nuevas armas generadas")
	else:
		push_error("WeaponManager: No se pudo acceder al weapon_spawner")
		return false
	
	print("WeaponManager: Reroll completado exitosamente")
	return true


# MODIFICAR la función return_weapon_to_storage para que use una nueva función auxiliar
func return_weapon_to_storage(from_x: int, from_y: int) -> bool:
	if not weapon_grid or not player_grid:
		return false
	
	# Verificar si hay espacio en el almacén
	if weapon_grid.get_empty_slots().is_empty():
		print("WeaponManager: WeaponGrid está lleno")
		return false
	
	# Desequipar del jugador
	var weapon = player_grid.unequip_weapon(from_x, from_y)
	if not weapon:
		return false
	
	# Devolver al almacén
	return_single_weapon_to_shop(weapon)
	
	return true

# Nueva función auxiliar para devolver una sola arma a la tienda
func return_single_weapon_to_shop(weapon: Carta):
	if not weapon or not weapon_grid:
		return
	
	var weapon_data = weapon.data as WeaponCardData
	weapon.queue_free()  # Destruir la instancia vieja
	weapon_grid.invoke_random_piece(weapon_data)  # Crear nueva en el almacén


func venderArma(carta:CartaArma):
	if not weapon_grid or not player_grid:
		return false
	
	var postion = carta.grid_pos
	
	# Desequipar del jugador
	var weapon = player_grid.unequip_weapon(postion.x, postion.y)
	if not weapon:
		return false

func verificar_transferencia(from_x: int, from_y: int) -> bool:
	if player_grid.is_full():
		return false
	
	#Verificar armas disponibles
	var available_weapons = weapon_grid.get_all_weapons()
	if available_weapons.is_empty():
		return false
	
	var validacion_final:bool = weapon_grid.verificar_saldo_suficiente(from_x,from_y)

	return validacion_final

func _on_carta_clikeada(carta:Carta):
	var postion = carta.grid_pos
	var success = transfer_weapon_to_player(postion.x, postion.y)
	weapon_spawner.place_weapon()
	if success:
		print("WeaponManager: Arma equipada exitosamente mediante doble click")
	else:
		print("WeaponManager: Fallo al equipar arma mediante doble click")
