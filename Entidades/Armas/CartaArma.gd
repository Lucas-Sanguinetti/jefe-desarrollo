extends Carta
class_name CartaArma

# Estado específico de armas
@export var can_attack: bool = true
# Referencias específicas
var ataque_label: Label
var traits_label: Label 

var ataque:int 
# Doble click (solo armas en WeaponGrid)
var click_timer: float = 0.0
var click_threshold: float = 0.3
var click_count: int = 0



# IMPLEMENTACIÓN DE MÉTODOS VIRTUALES
func _initialize_references() -> void:
	super._initialize_references()
	ataque_label = get_node_or_null("Ataque")
	traits_label = get_node_or_null("WeaponTraits")
	
	if not ataque_label:
		push_error("CartaArma: Falta nodo 'Ataque'")
	if not traits_label:
		push_error("CartaArma: Falta nodo 'WeaponTraits'")

func _setup_specific_ui() -> void:
	var weapon_data = data as WeaponCardData
	if not weapon_data:
		push_error("CartaArma requiere WeaponCardData")
		return
	ataque = weapon_data.attack
	if traits_label:
		traits_label.text = _get_traits_text(weapon_data)


func _apply_data_to_ui() -> void:
	if ataque_label:
		ataque_label.text = str(ataque)
	


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

func attack(target: Carta) -> bool:
	if not can_be_selected_for_attack():
		return false
	if not target.can_be_targeted():
		return false
	
	var weapon_data = data as WeaponCardData
	var weapon_attack = weapon_data.attack
	
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
	
	# Bloquear arma
	can_attack = false
	set_card_state(CardState.CANNOT_ATTACK)
	create_attack_effect(target)
	
	return true

func reset_attack_ability() -> void:
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

func _apply_lifesteal(weapon_attack: int, target: Carta) -> void:
	var lifesteal_amount = 0
	for traits in data.traits:
		if traits is RobaVida:
			lifesteal_amount = traits.get_lifesteal_amount(weapon_attack, target)
	
	if lifesteal_amount > 0 and LifeManager.get_life() > 0:
		LifeManager.gainLife(lifesteal_amount)

func _get_traits_text(weapon_data: WeaponCardData) -> String:
	var texto: String = ""
	for traits in weapon_data.traits:
		texto += "* %s\n" % [traits.trait_name]
	return texto

## Estructura de las Escenas
