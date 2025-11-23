class_name SpellEffects extends Node

# Este archivo estará listo para cuando quieras agregar animaciones

signal effect_started(effect_id: String, target)
signal effect_finished(effect_id: String, target)

var custom_effects: Dictionary = {}  # effect_id -> Callable

func _ready():
	_register_all_custom_effects()

func _register_all_custom_effects():
	pass

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
	#Debug
	print("SpellEffects: Aplicando '%s' (id: %s, categoría: %s)" % [
		spell.name,
		spell.effect_id if spell.effect_id != "" else "genérico",
		spell.get_category_string()
	])
	
	emit_signal("effect_started", spell.effect_id, target)
	
	# PRIORIDAD 1: Buscar efecto personalizado por ID
	if spell.effect_id != "" and spell.effect_id in custom_effects:
		var callback = custom_effects[spell.effect_id]
		callback.call(spell, target)
	
	# PRIORIDAD 2: Usar categoría genérica si no hay ID
	else:
		_apply_generic_effect(spell, target)
	
	emit_signal("effect_finished", spell.effect_id, target)

func _apply_generic_effect(spell: SpellCardData, target):
	match spell.effect_category:
		SpellCardData.EffectCategory.DAMAGE:
			_generic_damage(target, spell.effect_value)
		
		SpellCardData.EffectCategory.HEALING:
			_generic_heal(spell.effect_value)
		
		SpellCardData.EffectCategory.BUFF:
			_generic_weapon_buff(target, spell.effect_value)
		
		SpellCardData.EffectCategory.UTILITY:
			push_warning("SpellEffects: Utilidad genérica sin implementar para '%s'" % spell.name)
		
		SpellCardData.EffectCategory.SUMMON:
			_generic_summon_monster()
		
		SpellCardData.EffectCategory.ECONOMY:
			_generic_gain_money(spell.effect_value)
			
func _generic_damage(target: CartaMonstruo, value: int):
	if not target or not target is CartaMonstruo:
		push_error("SpellEffects: Objetivo inválido para daño genérico")
		return
	
	target.take_damage(value)
	print("SpellEffects: Daño genérico - %d a %s" % [value, target.name])

func _generic_heal(value: int):
	push_warning("SpellEffects: Acordate de implementar TurnManager y descomentar lo de abajo")
	#if not TurnManager.can_heal():
		#push_warning("SpellEffects: Curación bloqueada")
		#return
	
	LifeManager.gainLife(value)
	print("SpellEffects: Curación genérica - +%d HP" % value)

func _generic_weapon_buff(target: CartaArma, bonus: int):
	if not target or not target is CartaArma:
		push_error("SpellEffects: Objetivo inválido para buff genérico")
		return
		
	target.actualizar_Ataque(bonus)
	print("SpellEffects: Buff genérico - +%d ataque a %s" % [bonus, target.name])

func _generic_summon_monster():
	var monster_grid = _get_monster_grid()
	if not monster_grid or monster_grid.get_empty_cells().is_empty():
		push_warning("SpellEffects: No hay espacio para invocar")
		return
	
	var monster_data = MonsterDeck.draw1()
	if not monster_data:
		push_warning("SpellEffects: Mazo de monstruos vacío")
		return
	
	monster_grid.invoke_random_piece(monster_data)
	print("SpellEffects: Invocación genérica")

func _generic_gain_money(amount: int):
	MoneyManager.ganarMonedas(amount)
	print("SpellEffects: Economía genérica - +%d monedas" % amount)
	
# ============================================
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

# ============================================
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
	
