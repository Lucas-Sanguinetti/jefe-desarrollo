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
var abilities_description: Dictionary = {}

# INICIALIZACIÓN
func _ready():
	add_to_group("AbilitySystem")
	_register_all_abilities()
	print("AbilitySystem: Inicializado con %d habilidades" % custom_abilities.size())

func _register_all_abilities():
	register_ability("Bateria", _ability_recharge_weapon)
	register_ability("Magica", _ability_draw_spell)
	register_ability("Mercenario", _ability_mercenario)
	register_ability("Berserk", _ability_berserk)
	register_ability("Endurecer", _ability_endurecer)
	

# API PÚBLICA
func register_ability(ability_id: String, callback: Callable):
	custom_abilities[ability_id] = callback
	print("AbilitySystem: Registrada '%s'" % ability_id)
	
func get_description(ability_id: String):
	return abilities_description[ability_id]

func activate_weapon_ability(weapon: CartaArma):
	if not weapon or not weapon.data:
		return 
	
	var weapon_data = weapon.data as WeaponCardData
	if not weapon_data or not weapon_data.has_ability():
		print("AbilitySystem: Arma sin habilidad")
		return 
	
	var ability = weapon_data.ability
	
	print("AbilitySystem: Activando '%s' de %s" % [ability.ability_name, weapon.name])
	
	if not _can_use_ability_now(weapon, ability):
		print("AbilitySystem: ✗ No se puede usar la habilidad ahora")
		return
	
	# Determinar si necesita objetivo
	match ability.target_type:
		WeaponAbilityData.TargetType.NONE:
			# Auto-cast inmediato
			_execute_ability(weapon, ability, null)
		
		WeaponAbilityData.TargetType.WEAPON:
			# Iniciar selección de objetivo
			_start_target_selection(weapon, ability)


@warning_ignore("unused_parameter")
func _can_use_ability_now(weapon: CartaArma, ability: WeaponAbilityData)-> bool:
	match ability.ability_id:
		"Bateria":
			var other_weapons = get_all_other_weapons()
			if other_weapons.is_empty():
				return false  # No hay otras armas
			var has_discharged = other_weapons.any(func(w): return not w.is_charged())
			if not has_discharged:
				return false  # Todas están cargadas
		"Magica":
			var player_spells = _get_player_spells()
			if player_spells.is_full():
				return false # Mano de jugador llena
			# Opcional segun decision lucas
			var spell_deck = _get_spell_deck()
			if spell_deck.get_total_cards() < 1:
				return false #No hay cartas en el mazo
		"Mercenario":
			if MoneyManager.get_money() < 1:
				print("AbilitySystem: ✗ Mercenario requiere 1 moneda (tienes %d)" % MoneyManager.get_money())
				return false

	return true

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
@warning_ignore("unused_parameter")
func _ability_recharge_weapon(weapon: CartaArma, _ability , target: CartaArma)-> bool:
	if not target or not target is CartaArma:
		return false
	
	if target.is_charged():
		return false
	
	target.recharge()
	return true
	
@warning_ignore("unused_parameter")
func _ability_draw_spell(weapon: CartaArma, ability: WeaponAbilityData, _target)-> bool:
	var cards_to_draw = ability.value_1
	var spell_deck = _get_spell_deck()
	var hand = _get_player_spells()
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
	if drawn_count > 0:
		return true
	else:
		return false


@warning_ignore("unused_parameter")
func _ability_mercenario(weapon: CartaArma, ability: WeaponAbilityData , target: CartaArma)-> bool:
	if not target or not target is CartaArma:
		return false
	if not target.is_charged():
		return false
	if MoneyManager.get_money() < 1:
		return false
	MoneyManager.perderMonedas(1)
	target.actualizar_Ataque(ability.value_1)
	return true
	
@warning_ignore("unused_parameter")
func _ability_berserk(weapon: CartaArma, ability: WeaponAbilityData, _target) -> bool:
	var players_weapons = _get_player_weapon()
	players_weapons.active_berserk()
	return true

@warning_ignore("unused_parameter")
func _ability_endurecer(weapon: CartaArma, ability: WeaponAbilityData, _target) -> bool:
	
	var players_weapons = _get_player_weapon()
	players_weapons.active_endurance(ability.value_1)
	return true

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
func _get_player_weapon():
	return get_tree().get_first_node_in_group("PlayerWeapons")
	
func _get_player_spells():
	return get_tree().get_first_node_in_group("Hand")
	
func _get_spell_deck():
	return get_tree().get_first_node_in_group("SpellDeck")

func get_all_other_weapons():
	var player_grid = get_tree().get_first_node_in_group("PlayerWeaponGrid")
	return player_grid.get_all_weapons()
