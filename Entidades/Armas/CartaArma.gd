extends Carta
class_name CartaArma

# Estado específico de armas
@export var can_attack: bool = true

# Referencias UI
var ataque_label: Label
var traits_label: Label 
var niveles_sprite: Sprite2D
var element_sprite: TextureRect
var backsprite_sprite: TextureRect

#Variables de la Escena
var ataque:int 
var nivel:int 
var rasgos:Array
var element: WeaponCardData.ElementType
var habilidad: WeaponAbilityData

# Doble click (solo armas en WeaponGrid)
var click_timer: float = 0.0
var click_threshold: float = 0.3
var click_count: int = 0

#Audio
@onready var draw_sword: AudioStreamPlayer = $DrawSword
@onready var sword_hit: AudioStreamPlayer = $SwordHit
var draw_sword_sound: AudioStream
var sword_hit_sound: AudioStream

#Señales
signal ability_activated(weapon: CartaArma)
signal weapon_recharged(weapon: CartaArma)
signal weapon_discharged(weapon: CartaArma)

# IMPLEMENTACIÓN DE MÉTODOS VIRTUALES
func _initialize_references() -> void:
	super._initialize_references()
	ataque_label = get_node_or_null("Ataque")
	traits_label = get_node_or_null("WeaponTraits")
	niveles_sprite = get_node_or_null("Niveles")
	element_sprite = get_node_or_null("Element")
	backsprite_sprite = get_node_or_null("BackSprite")
	
	
	if not ataque_label:
		push_error("CartaArma: Falta nodo 'Ataque'")
	if not traits_label:
		push_error("CartaArma: Falta nodo 'WeaponTraits'")
	if not niveles_sprite:
		push_error("CartaArma: Falta nodo 'Niveles'")

func _setup_specific_ui() -> void:
	var weapon_data = data as WeaponCardData
	if not weapon_data:
		push_error("CartaArma requiere WeaponCardData")
		return
	ataque = weapon_data.attack
	element = weapon_data.element_type
	if traits_label:
		traits_label.text = _get_traits_text(weapon_data)
	nivel = weapon_data.nivel
	rasgos = weapon_data.traits
	sword_hit_sound = weapon_data.swordHit
	draw_sword_sound = weapon_data.drawSword
	habilidad = weapon_data.ability
	
	if niveles_sprite:
		niveles_sprite.set_nivel(nivel)
	if element_sprite:
		element_sprite.texture = weapon_data.element
	if backsprite_sprite:
		backsprite_sprite.texture = weapon_data.backsprite
	_apply_data_to_ui()


func _apply_data_to_ui() -> void:
	if ataque_label:
		ataque_label.text = str(ataque)

# SISTEMA DE CARGAS
func _update_charge_indicator():
	if can_attack:
		set_card_state(CardState.NORMAL)
		rotation_degrees = 0  # ✅ Posición normal
		modulate = Color.WHITE  # ✅ Color normal
		print("%s: Cambiando de CardState a Normal" % name)
	else:
		set_card_state(CardState.CANNOT_ATTACK)
		rotation_degrees = 90  # ✅ Voltear arma
		modulate = Color(0.7, 0.7, 0.7)  # ✅ Color apagado
		print("%s: Cambiando de CardState a CANNOT_ATTACK" % name)
	_update_visual_state()


func is_charged():
	return can_attack

func recharge():
	if can_attack:
		print("%s: Ya esta cargada",name)
		return
	can_attack = true
	_update_charge_indicator()
	emit_signal("weapon_recharged", self)
	print("%s: RECARGADA" % name)

func discharge():
	if not can_attack:
		print("%s: Ya está descargada" % name)
		return
	can_attack = false
	_update_charge_indicator()
	emit_signal("weapon_discharged", self)
	print("%s: DESCARGADA" % name)

#HABILIDADES
func can_use_ability() -> bool:
	# Verificar que esté en el grid del jugador
	if not parent_grid or not parent_grid is PlayerWeaponGrid:
		return false
	
	# Verificar que esté cargada
	if not can_attack:
		print("%s: Descargada, no puede usar habilidad" % name)
		return false
	
	# Verificar que tenga habilidad
	var weapon_data = data as WeaponCardData
	if not weapon_data or not weapon_data.has_ability():
		print("%s: Sin habilidad" % name)
		return false
	
	return true

func use_ability() -> void:
	if not can_use_ability():
		return
	
	print("%s: Activando habilidad..." % name)
	
	# Emitir señal
	emit_signal("ability_activated", self)
	
	# Ejecutar habilidad a través del AbilitySystem
	var ability_system = get_tree().get_first_node_in_group("AbilitySystem")
	if ability_system:
		var success = ability_system.activate_weapon_ability(self)
		if not success:
			print("%s: Habilidad falló - arma NO descargada" % name)
	else:
		push_error("CartaArma: No se encontró AbilitySystem")

# CAPACIDADES DE COMBATE
func can_be_selected_for_attack() -> bool:
	var is_in_player_grid = parent_grid != null and parent_grid is PlayerWeaponGrid
	return is_in_player_grid and can_attack and current_state != CardState.CANNOT_ATTACK

func can_be_double_clicked() -> bool:
	if not data is WeaponCardData:
		return false
	if not parent_grid:
		return false
	
	var is_weapon_grid = parent_grid.get_script() and \
		parent_grid.get_script().get_global_name() == "WeaponGrid"
	return is_weapon_grid


# LÓGICA DE COMBATE
func select_for_attack() -> void:
	if can_be_selected_for_attack():
		set_card_state(CardState.SELECTED_FOR_ATTACK)
		emit_signal("card_selected_for_attack", self)
		draw_sword.playSound(draw_sword_sound)

func attack(target: CartaMonstruo) -> bool:
	if not can_be_selected_for_attack():
		return false
	if not target.can_be_targeted():
		return false
	
	var weapon_data = data as WeaponCardData
	var weapon_attack = ataque
	
	# Aplicar traits del arma
	for traits in weapon_data.traits:
		weapon_attack = traits.do_damage(self, target, weapon_attack)
	
	# Calcular daño al jugador
	var player_damage = _calculate_player_damage(target)
	
	# Aplicar daño
	if player_damage != 0:
		LifeManager.looseLife(player_damage)
	
	# Aplicar habilidades de estado
	weapon_attack = _apply_state_attack_abilities(weapon_attack)
	
	target.take_damage(weapon_attack, self)
	
	# Lifesteal
	_apply_lifesteal(weapon_attack, target)
	
	#Primer ataque
	if parent_grid and parent_grid is PlayerWeaponGrid:
		parent_grid.mark_attack_used()
	
	# Bloquear arma
	discharge()
	
	create_attack_effect(target)
	
	sword_hit.playSound(sword_hit_sound)
	return true

func reset_attack_ability() -> void:
	recharge()

func reset_attack_stats() -> void:
	var weapon_data = data as WeaponCardData
	ataque = weapon_data.attack
	_apply_data_to_ui()

func block_attack_ability() -> void:
	discharge()

# MANEJOS DE INPUT
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed: 
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()

func _handle_left_click() -> void:
	if parent_grid and parent_grid.get_script():
		var is_weapon_grid = parent_grid.get_script().get_global_name() == "WeaponGrid"
		
		if is_weapon_grid:
			click_count += 1
			click_timer = click_threshold
			
			if click_count >= 2:
				_on_double_click()
				click_count = 0
				click_timer = 0

func _handle_right_click() -> void:
	if parent_grid and parent_grid is PlayerWeaponGrid:
		if can_use_ability():
			use_ability()
		else:
			# Dar feedback de por qué no puede usar
			if not can_attack:
				print("%s: Descargada, no puede usar habilidad" % name)
			else:
				var weapon_data = data as WeaponCardData
				if not weapon_data or not weapon_data.has_ability():
					print("%s: Esta arma no tiene habilidad" % name)
				else:
					print("%s: No puede usar habilidad" % name)

func _on_double_click() -> void:
	emit_signal("card_double_clicked", self)


# UTILIDADES PRIVADAS
func _calculate_player_damage(target: Carta) -> int:
	var monster_data = target.data as MonsterCardData
	var player_damage = monster_data.attack
	
	# Aplicar traits del arma sobre el daño recibido
	for traits in data.traits:
		player_damage = traits.on_player_damage(player_damage, target)
	
	# Aplicar traits del monstruo
	for traits in monster_data.traits:
		player_damage = traits.on_player_damage(player_damage, target)
	
	# Aplicar habilidades de estado
	player_damage = _apply_state_damage_abilities(player_damage)
	
	return player_damage

func _apply_state_damage_abilities(player_damage: int):
	var playerWeapons = get_tree().get_first_node_in_group("PlayerWeapons")
	
	if playerWeapons.berserkState:
		player_damage = player_damage * 2
	
	if playerWeapons.enduranceState:
		player_damage = max(player_damage - playerWeapons.resistencia, 0)
	
	return player_damage

func _apply_state_attack_abilities(weapon_damage: int):
	var playerWeapons = get_tree().get_first_node_in_group("PlayerWeapons")
	
	if playerWeapons.berserkState:
		weapon_damage = weapon_damage * 2
	
	return weapon_damage

func _apply_lifesteal(weapon_attack: int, target: CartaMonstruo) -> void:
	var lifesteal_amount = 0
	for traits in data.traits:
		if traits is RobaVida:
			lifesteal_amount = traits.get_lifesteal_amount(self,weapon_attack, target)
	
	lifesteal_amount = min(lifesteal_amount, target.hp_actual)
	
	if lifesteal_amount > 0 and LifeManager.get_life() > 0:
		LifeManager.gainLife(lifesteal_amount)

func _get_traits_text(weapon_data: WeaponCardData) -> String:
	var texto: String = ""
	for traits in weapon_data.traits:
		texto += " %s \n" % [traits.trait_name]
	if habilidad != null:
		texto += " %s\n " % [habilidad.ability_name]
	return texto

#UTILIDADES PUBLICAS
func actualizar_Ataque(bonus: int):
	ataque = ataque + bonus
	_apply_data_to_ui()

func actLabel(label: Label) -> void:
	var text = "Ataque: %d\n" % [ataque]
	# Agregar traits
	if not rasgos.is_empty():
		for rasgo in rasgos:
			text += "%s :\n" % [rasgo.trait_name]
			text += " %s\n" % [rasgo.trait_description]
	else:
		text += "Sin traits\n"
	if habilidad != null:
			text += "%s (click derecho) :\n " % [habilidad.ability_name]
			text += " %s\n" % [habilidad.ability_description]
	
	
	label.text = text
