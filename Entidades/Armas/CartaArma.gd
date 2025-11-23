extends Carta
class_name CartaArma

# Estado específico de armas
@export var can_attack: bool = true
# Referencias específicas
var ataque_label: Label
var traits_label: Label 
var niveles_sprite: Sprite2D
var element_sprite: TextureRect
var backsprite_sprite: TextureRect

var backsprite: Texture2D
var ataque:int 
var nivel:int 
var rasgos:Array
var element:Texture2D
# Doble click (solo armas en WeaponGrid)
var click_timer: float = 0.0
var click_threshold: float = 0.3
var click_count: int = 0

@onready var draw_sword: AudioStreamPlayer = $DrawSword
@onready var sword_hit: AudioStreamPlayer = $SwordHit




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
	element = weapon_data.element
	backsprite = weapon_data.backsprite
	if traits_label:
		traits_label.text = _get_traits_text(weapon_data)
	nivel = weapon_data.nivel
	rasgos = weapon_data.traits
	_apply_data_to_ui()


func _apply_data_to_ui() -> void:
	if ataque_label:
		ataque_label.text = str(ataque)
	if niveles_sprite:
		niveles_sprite.set_nivel(nivel)
	if element_sprite:
		element_sprite.texture = element
	if backsprite_sprite:
		backsprite_sprite.texture = backsprite
		backsprite_sprite.scale = Vector2(0.5, 0.5)
	


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
		draw_sword.play()

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
	
	target.take_damage(weapon_attack, self)
	
	# Lifesteal
	_apply_lifesteal(weapon_attack, target)
	
	#Primer ataque
	if parent_grid and parent_grid is PlayerWeaponGrid:
		parent_grid.mark_attack_used()
	
	# Bloquear arma
	can_attack = false
	set_card_state(CardState.CANNOT_ATTACK)
	create_attack_effect(target)
	
	sword_hit.play()
	return true

func reset_attack_ability() -> void:
	var weapon_data = data as WeaponCardData
	ataque = weapon_data.attack
	can_attack = true
	set_card_state(CardState.NORMAL)

func block_attack_ability() -> void:
	can_attack = false
	set_card_state(CardState.CANNOT_ATTACK)


# SISTEMA DE DOBLE CLICK


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click() -> void:
	if not can_be_double_clicked():
		return
	
	click_count += 1
	click_timer = click_threshold
	
	if click_count >= 2:
		_on_double_click()
		click_count = 0
		click_timer = 0

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
	return player_damage

func _apply_lifesteal(weapon_attack: int, target: CartaMonstruo) -> void:
	var lifesteal_amount = 0
	for traits in data.traits:
		if traits is RobaVida:
			lifesteal_amount = traits.get_lifesteal_amount(weapon_attack, target)
	
	lifesteal_amount = min(lifesteal_amount, target.hp_actual)
	
	if lifesteal_amount > 0 and LifeManager.get_life() > 0:
		LifeManager.gainLife(lifesteal_amount)

func _get_traits_text(weapon_data: WeaponCardData) -> String:
	var texto: String = ""
	for traits in weapon_data.traits:
		texto += "* %s\n" % [traits.trait_name]
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
			text += "* %s\n" % [rasgo.trait_name]
			text += " %s\n" % [rasgo.trait_description]
	else:
		text += "Sin traits\n"
	
	label.text = text
