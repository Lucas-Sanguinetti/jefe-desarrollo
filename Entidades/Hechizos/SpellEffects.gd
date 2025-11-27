class_name SpellEffects extends Node

# Este archivo estará listo para cuando quieras agregar animaciones

signal effect_started(effect_id: String, target)
signal effect_finished(effect_id: String, target)

var custom_effects: Dictionary = {}  # effect_id -> Callable

func _ready():
	_register_all_custom_effects()

func _register_all_custom_effects():
	register_effect("cambiazo", _effect_cambiazo)
	register_effect("bateria", _effect_bateria)
	

func register_effect(effect_id: String, callback: Callable):
	if effect_id in custom_effects:
		push_warning("SpellEffects: Sobrescribiendo efecto '%s'" % effect_id)
	custom_effects[effect_id] = callback
	print("SpellEffects: Registrado '%s'" % effect_id)
	
func unregister_effect(effect_id: String):
	custom_effects.erase(effect_id)

func has_custom_effect(effect_id: String) -> bool:
	return effect_id in custom_effects

func apply_spell_effect(spell: SpellCardData, target = null):
	if not spell:
		push_error("SpellEffects: Spell data es null")
		return
	
	emit_signal("effect_started", spell.effect_id, target)
	var success = false
	# PRIORIDAD 1: Buscar efecto personalizado por ID
	if spell.effect_id != "" and spell.effect_id in custom_effects:
		var callback = custom_effects[spell.effect_id]
		success = callback.call(spell, target)
	
	# PRIORIDAD 2: Usar categoría genérica si no hay ID
	else:
		success = _apply_generic_effect(spell, target)
	
	emit_signal("effect_finished", spell.effect_id, target)
	
	return success
	
# Hechizos Generales
# ============================================
func _apply_generic_effect(spell: SpellCardData, target):
	match spell.effect_category:
		SpellCardData.EffectCategory.DAMAGE:
			_generic_damage(target, spell.effect_value)
		
		SpellCardData.EffectCategory.HEALING:
			_generic_heal(spell.effect_value)
		
		SpellCardData.EffectCategory.BUFF:
			_generic_weapon_buff(target, spell.effect_value)
		
		SpellCardData.EffectCategory.UTILITY:
			_generic_utility()
		
		SpellCardData.EffectCategory.SUMMON:
			_generic_summon_monster()
		
		SpellCardData.EffectCategory.ECONOMY:
			_generic_gain_money(spell.effect_value)
			
func _generic_damage(target: CartaMonstruo, value: int) -> bool:
	if _validate_monster_target(target):
		push_error("SpellEffects: Objetivo inválido para daño genérico")
		return false
	
	target.take_damage(value)
	return true

func _generic_heal(value: int) -> bool:
	if not TurnManager.can_heal:
		push_warning("SpellEffects: Curación bloqueada")
		return false
	
	LifeManager.gainLife(value)
	return true

func _generic_weapon_buff(target: CartaArma, bonus: int)-> bool:
	if not _validate_weapon_target(target):
		push_error("SpellEffects: Objetivo inválido para buff genérico")
		return false
		
	if not target.is_charged():
		return false
		
	target.actualizar_Ataque(bonus)
	return true

func _generic_summon_monster()-> bool:
	var monster_grid = _get_monster_grid()
	if not monster_grid or monster_grid.get_empty_cells().is_empty():
		push_warning("SpellEffects: No hay espacio para invocar")
		return false
	
	var monster_data = MonsterDeck.draw1()
	if not monster_data:
		push_warning("SpellEffects: Mazo de monstruos vacío")
		return false
	
	monster_grid.invoke_random_piece(monster_data)
	return true

func _generic_gain_money(amount: int)-> bool:
	MoneyManager.ganarMonedas(amount)
	return true

func _generic_utility() -> bool:
	print("SpellEffects: Utilidad generica no existe")
	return true

# HECHIZOS ESPECIALES
# ============================================
@warning_ignore("unused_parameter")
func _effect_cambiazo(spell: SpellCardData, target: CartaArma)-> bool:
	if not _validate_weapon_target(target):
		return false
	
	var player_weapon_spawner = get_tree().get_first_node_in_group("PlayerWeapons")
	var weapon_manager = get_tree().get_first_node_in_group("WeaponManager")
	if player_weapon_spawner.cantidad_armas() > 1:
		if not target.is_charged():
			return false
		MoneyManager.ganarMonedas(target.nivel)
		weapon_manager.venderArma(target)
	return true
	
@warning_ignore("unused_parameter")
func _effect_bateria(spell: SpellCardData,target: CartaArma)-> bool:
	if not _validate_weapon_target(target):
		return false
		
	if target.is_charged():
		return false
		
	target.recharge()
	return true

# VALIDACIÓN DE OBJETIVOS
# ============================================
func _validate_monster_target(target) -> bool:
	if not target or not target is CartaMonstruo:
		push_error("SpellEffects: Objetivo debe ser CartaMonstruo")
		return false
	return true

func _validate_weapon_target(target) -> bool:
	if not target or not target is CartaArma:
		push_error("SpellEffects: Objetivo debe ser CartaArma")
		return false
	return true

# HELPERS
# ============================================
func _get_monster_grid() -> MonsterGrid:
	var grid = get_tree().get_first_node_in_group("MonsterGrid")
	if not grid:
		push_error("SpellEffects: No se encontró MonsterGrid")
	return grid

func _get_player_weapon_grid() -> PlayerWeaponGrid:
	var grid = get_tree().get_first_node_in_group("PlayerWeaponGrid")
	if not grid:
		push_error("SpellEffects: No se encontró PlayerWeaponGrid")
	return grid

func _get_hand() -> Hand:
	var hand = get_tree().get_first_node_in_group("Hand")
	if not hand:
		push_error("SpellEffects: No se encontró Hand")
	return hand	
	
