extends Node
class_name AbilitySystem 

# SEÑALES
signal ability_executed(weapon: CartaArma, ability: WeaponAbilityData, target)

# ESTADO
var active_weapon: CartaArma = null
var active_ability: WeaponAbilityData = null
var waiting_for_target: bool = false

# REGISTRO DE EFECTOS PERSONALIZADOS
var custom_abilities: Dictionary = {}

# INICIALIZACIÓN
func _ready():
	add_to_group("AbilitySystem")
	_register_all_abilities()
	print("AbilitySystem: Inicializado con %d habilidades" % custom_abilities.size())

func _register_all_abilities():
	register_ability("Bateria", _ability_recharge_weapon)
	register_ability("Magica", _ability_draw_spell)

# API PÚBLICA
func register_ability(ability_id: String, callback: Callable):
	custom_abilities[ability_id] = callback
	print("AbilitySystem: Registrada '%s'" % ability_id)

func activate_weapon_ability(weapon: CartaArma):	
	if not weapon or not weapon.data:
		return
	
	var weapon_data = weapon.data as WeaponCardData
	if not weapon_data or not weapon_data.has_ability():
		print("AbilitySystem: Arma sin habilidad")
		return
	
	var ability = weapon_data.ability
	
	print("AbilitySystem: Activando '%s' de %s" % [ability.ability_name, weapon.name])
	
	# Determinar si necesita objetivo
	match ability.target_type:
		WeaponAbilityData.TargetType.NONE:
			# Auto-cast inmediato
			_execute_ability(weapon, ability, null)
		
		WeaponAbilityData.TargetType.WEAPON:
			# Iniciar selección de objetivo
			_start_target_selection(weapon, ability)

func target_selected(target):
	if not waiting_for_target or not active_weapon or not active_ability:
		return
	
	# Validar objetivo
	if not active_ability.is_valid_target(target):
		print("AbilitySystem: Objetivo inválido")
		return
	
	print("AbilitySystem: Objetivo seleccionado")
	_execute_ability(active_weapon, active_ability, target)

func cancel_selection():
	if active_weapon:
		active_weapon.set_card_state(Carta.CardState.NORMAL)
	
	active_weapon = null
	active_ability = null
	waiting_for_target = false

# EJECUCIÓN DE HABILIDADES
func _start_target_selection(weapon: CartaArma, ability: WeaponAbilityData):
	cancel_selection()
	
	active_weapon = weapon
	active_ability = ability
	waiting_for_target = true
	
	weapon.set_card_state(Carta.CardState.SELECTED_FOR_ATTACK)
	
	print("AbilitySystem: Esperando objetivo (%s)" % ability.get_target_type_string())

func _execute_ability(weapon: CartaArma, ability: WeaponAbilityData, target):
	print("AbilitySystem: Ejecutando '%s'" % ability.ability_name)
	
	# Buscar efecto personalizado
	if ability.ability_id != "" and ability.ability_id in custom_abilities:
		var callback = custom_abilities[ability.ability_id]
		callback.call(weapon, ability, target)
	else:
		push_warning("AbilitySystem: Habilidad '%s' sin implementar" % ability.ability_id)
	cancel_selection()
	weapon.discharge()
	
	emit_signal("ability_executed", weapon, ability, target)
	


# HABILIDADES IMPLEMENTADAS

# Recargar otra arma
func _ability_recharge_weapon(weapon: CartaArma, _ability , target: CartaArma):
	if not target or not target is CartaArma:
		return
	if target.is_charged():
		return
	
	target.recharge()
	
	print("AbilitySystem: %s recargó a %s" % [weapon.name, target.name])
	
# Sacar un hechizo
func _ability_draw_spell(weapon: CartaArma, ability: WeaponAbilityData, _target):
	var cards_to_draw = ability.value_1
	var spell_deck = get_tree().get_first_node_in_group("SpellDeck")
	var hand = get_tree().get_first_node_in_group("Hand")
	var drawn_count = 0
	
	for i in range(cards_to_draw):
		# Reviso estado de la mano
		if hand.is_full():
			break
		#Saco la carta
		var card = spell_deck.draw_card()
		#Reviso si mazo tiene cartas disponibles
		if not card:
			break
		#Agrega a la mano e incrementa contador
		if hand.add_card(card):
			drawn_count += 1
	
	print("AbilitySystem: %s robo %d Hechizos" % [weapon.name, drawn_count])

# MANEJO DE INPUT (para seleccionar objetivos)
func _input(event):
	if not waiting_for_target:
		return
	
	if event is InputEventMouseButton and event.pressed:
		# Cualquier botón del mouse sirve para seleccionar
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			var clicked_target = _raycast_check_for_target()
			
			if clicked_target:
				target_selected(clicked_target)
			else:
				# Click en área vacía = cancelar
				print("AbilitySystem: Selección cancelada")
				cancel_selection()

func _raycast_check_for_target():
	"""Detecta qué carta hay bajo el mouse"""
	var world := get_tree().root.get_world_2d()
	var space_state := world.direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_viewport().get_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	
	var result: Array = space_state.intersect_point(parameters)

	if result.size() > 0:
		var collider := result[0]["collider"] as Area2D
		
		if collider:
			var collider_parent := collider.get_parent()
			
			match active_ability.target_type:
				WeaponAbilityData.TargetType.WEAPON:
					if collider_parent is CartaArma:
						return collider_parent as CartaArma
	
	return null

# HELPERS
func _get_monster_grid() -> MonsterGrid:
	return get_tree().get_first_node_in_group("MonsterGrid")

func _get_player_weapon_grid() -> PlayerWeaponGrid:
	return get_tree().get_first_node_in_group("PlayerWeaponGrid")
