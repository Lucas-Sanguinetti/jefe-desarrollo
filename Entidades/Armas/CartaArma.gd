extends Carta
class_name CartaArma

# Estado específico de armas
@export var can_attack: bool = true
var turn_purchased: int = -1  # En qué turno fue comprada (-1 = no comprada este turno)
var can_be_sold: bool = true 

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

#Animaciones
var animation_manager: WeaponAnimationManager = null

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
	
	call_deferred("_get_animation_manager")

func _setup_specific_ui() -> void:
	var weapon_data = data as WeaponCardData
	if not weapon_data:
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

func _get_animation_manager():
	animation_manager = get_tree().get_first_node_in_group("WeaponAnimationManager")
	if not animation_manager:
		return
		#push_warning("CartaArma: No se encontró WeaponAnimationManager")

# SISTEMA DE CARGAS
func _update_charge_indicator():
	if can_attack:
		set_card_state(CardState.NORMAL)
		#rotation_degrees = 0  # ✅ Posición normal
		#modulate = Color.WHITE  # ✅ Color normal
		print("%s: Cambiando de CardState a Normal" % name)
	else:
		set_card_state(CardState.CANNOT_ATTACK)
		#rotation_degrees = 90  # ✅ Voltear arma
		#modulate = Color(0.7, 0.7, 0.7)  # ✅ Color apagado
		print("%s: Cambiando de CardState a CANNOT_ATTACK" % name)
	_update_visual_state()

func is_charged():
	return can_attack

func recharge():
	if can_attack:
		return
	can_attack = true
	_update_charge_indicator()
	emit_signal("weapon_recharged", self)

func discharge():
	if not can_attack:
		return
	can_attack = false
	_update_charge_indicator()
	emit_signal("weapon_discharged", self)

#HABILIDADES
func can_use_ability() -> bool:
	# Verificar que esté en el grid del jugador
	if not parent_grid or not parent_grid is PlayerWeaponGrid:
		return false
	
	# Verificar que esté cargada
	if not can_attack:
		return false
	
	# Verificar que tenga habilidad
	var weapon_data = data as WeaponCardData
	if not weapon_data or not weapon_data.has_ability():
		return false
	
	return true

func use_ability() -> void:
	if not can_use_ability():
		return

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
	
	LifeManager.snapshot_vida()
	

	var weapon_attack = ataque
	var monster_hp = target.hp_actual
	
	# Verificar si hay animación especial para esta arma
	var has_animation = false
	if animation_manager:
		has_animation = animation_manager.play_attack_animation(self, target)
	
	# Si hay animación, esperar a que termine antes de aplicar daño
	if has_animation:
		# Conectar señal para aplicar daño cuando el proyectil impacte
		if not animation_manager.projectile_hit.is_connected(_on_projectile_hit):
			animation_manager.projectile_hit.connect(_on_projectile_hit)
		
		# Guardar datos del ataque para aplicar después
		set_meta("pending_attack_target", target)
		set_meta("pending_attack_damage", weapon_attack)
		set_meta("pending_monster_hp", monster_hp)
		
		# Reproducir sonido de disparo
		draw_sword.playSound(draw_sword_sound)
		
		return true
	else:
		# Ataque normal sin animación especial
		return _execute_attack(target, weapon_attack, monster_hp)
		
func _on_projectile_hit(hit_target: Carta):
	# Verificar que sea nuestro objetivo
	#var pending_target = get_meta("pending_attack_target", null)
	var pending_target = get_meta("pending_attack_target")
	if hit_target != pending_target:
		return
	
	# Obtener datos del ataque pendiente
	var weapon_attack = get_meta("pending_attack_damage", 0)
	var monster_hp = get_meta("pending_monster_hp", 0)
	
	# Limpiar metadatos
	remove_meta("pending_attack_target")
	remove_meta("pending_attack_damage")
	remove_meta("pending_monster_hp")
	
	if animation_manager and animation_manager.projectile_hit.is_connected(_on_projectile_hit):
		animation_manager.projectile_hit.disconnect(_on_projectile_hit)
	# Ejecutar el daño
	_apply_attack_damage(hit_target, weapon_attack, monster_hp)
	# Reproducir sonido de impacto
	sword_hit.playSound(sword_hit_sound)
	
# REINICIOS

func reset_for_new_turn():
	if turn_purchased != -1 and turn_purchased < TurnManager.get_current_turn():
		can_be_sold = true
		print("%s: Ahora se puede vender" % name)
	reset_attack_ability()
	reset_attack_stats()
	reset_abilities_states()

func reset_attack_ability() -> void:
	recharge()

func reset_attack_stats() -> void:
	var weapon_data = data as WeaponCardData
	ataque = weapon_data.attack
	_apply_data_to_ui()

func reset_abilities_states():
	if get_trait_state("berserk_active", false):
		clear_trait_state("berserk_active")

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
			if not can_attack:
				#print("%s: Descargada, no puede usar habilidad" % name)
				pass
			else:
				var weapon_data = data as WeaponCardData
				if not weapon_data or not weapon_data.has_ability():
					#print("%s: Esta arma no tiene habilidad" % name)
					pass
				else:
					#print("%s: No puede usar habilidad" % name)
					pass

func _on_double_click() -> void:
	emit_signal("card_double_clicked", self)

# VENTA DEL ARMA
func mark_as_purchased():
	turn_purchased = TurnManager.get_current_turn()
	can_be_sold = false
	print("%s: Comprada en turno %d - No se puede vender hasta el próximo turno" % [name, turn_purchased])

# Método para verificar si se puede vender
func can_sell() -> bool:
	var current_turn = TurnManager.get_current_turn()
	
	# Si fue comprada en este turno, no se puede vender
	if turn_purchased == current_turn:
		print("%s: No se puede vender (comprada en este turno)" % name)
		return false
	
	return can_be_sold

# UTILIDADES PRIVADAS
func _calculate_player_damage(target: Carta) -> int:
	var monster_data = target.data as MonsterCardData
	var player_damage = monster_data.attack
	
	# Aplicar traits del arma sobre el daño recibido
	for traits in rasgos:
		player_damage = traits.on_player_damage(player_damage, target)
	
	# Aplicar traits del monstruo
	for traits in monster_data.traits:
		player_damage = traits.on_player_damage(player_damage, target)
	
	# Aplicar habilidades de estado
	player_damage = _apply_state_damage_abilities(player_damage)
	
	return player_damage

func _apply_state_damage_abilities(player_damage: int):
	var playerWeapons = get_tree().get_first_node_in_group("PlayerWeapons")
	
	if get_trait_state("berserk_active", false):
		player_damage = player_damage * 2
	
	if playerWeapons.enduranceState:
		player_damage = max(player_damage - playerWeapons.resistencia, 0)
	
	return player_damage

func _apply_attack_abilities(weapon_damage: int):
	
	if get_trait_state("berserk_active", false):
		weapon_damage = weapon_damage * 2
	
	return weapon_damage

func _apply_lifesteal(weapon_attack: int, target: CartaMonstruo, monster_hp: int) -> void:
	var lifesteal_amount = 0
	for traits in rasgos:
		if traits is RobaVida:
			lifesteal_amount = traits.get_lifesteal_amount(self,weapon_attack, target)
	
	lifesteal_amount = min(lifesteal_amount, monster_hp)
	
	if lifesteal_amount > 0 and LifeManager.get_life() > 0:
		LifeManager.gainLife(lifesteal_amount)
		

func _get_traits_text(weapon_data: WeaponCardData) -> String:
	var texto: String = ""
	for traits in rasgos:
		texto += " %s \n" % [traits.trait_name]
	if weapon_data.ability:
		texto += " %s \n" % [weapon_data.ability.ability_name]
	return texto

func _apply_attack_damage(target: Carta, weapon_attack: int, monster_hp: int):
	var final_damage = weapon_attack
	
	# Aplicar traits del arma
	for rasgo in rasgos:
		final_damage = rasgo.do_damage(self, target, final_damage)
	# Calcular daño al jugador
	var player_damage = _calculate_player_damage(target)
	
	# Aplicar daño al jugador
	if player_damage != 0:
		LifeManager.looseLife(player_damage)
	
	# Aplicar habilidades de estado
	final_damage = _apply_attack_abilities(final_damage)
	
	# Aplicar daño al monstruo
	target.take_damage(final_damage, self)
	
	# Lifesteal
	_apply_lifesteal(final_damage, target, monster_hp)
	
	if parent_grid and parent_grid is PlayerWeaponGrid:
			parent_grid.mark_attack_used()
			
	discharge()

func _execute_attack(target: CartaMonstruo, weapon_attack: int, monster_hp: int) -> bool:
	# Aplicar traits del arma
	for traits in rasgos:
		weapon_attack = traits.do_damage(self, target, weapon_attack)
	
	# Calcular daño al jugador
	var player_damage = _calculate_player_damage(target)
	
	# Aplicar daño al jugador
	if player_damage != 0:
		LifeManager.looseLife(player_damage)
	
	# Aplicar habilidades de estado
	weapon_attack = _apply_attack_abilities(weapon_attack)
	
	# Aplicar daño al monstruo
	target.take_damage(weapon_attack, self)
	
	# Lifesteal
	_apply_lifesteal(weapon_attack, target, monster_hp)
	
	# Marcar ataque usado
	if parent_grid and parent_grid is PlayerWeaponGrid:
		parent_grid.mark_attack_used()
	
	# Bloquear arma
	discharge()
	
	# Efectos visuales
	create_attack_effect(target)
	
	# Audio
	sword_hit.playSound(sword_hit_sound)
	
	return true
	
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
		text += "Sin pasivas\n"
	if habilidad != null:
			text += "%s (click derecho) :\n " % [habilidad.ability_name]
			text += " %s\n" % [habilidad.ability_description]
	
	label.text = text

func get_display_resource() -> Resource:
	var copy = data.duplicate()
	
	copy.attack = ataque

	return copy
