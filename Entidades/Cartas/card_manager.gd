extends Node2D

enum CombatState {
	NORMAL,
	SELECTING_WEAPON,
	WEAPON_SELECTED
}

var combat_state: CombatState = CombatState.NORMAL
var selected_weapon: Carta = null

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			handle_card_click()
func handle_card_click():
	var clicked_card = raycast_check_for_card()
	
	if clicked_card == null:
		# Click en área vacía - cancelar selección
		cancel_weapon_selection()
		return
	
	match combat_state:
		CombatState.NORMAL:
			# Intentar seleccionar un arma para atacar
			if clicked_card.can_be_selected_for_attack():
				select_weapon(clicked_card)
		
		CombatState.WEAPON_SELECTED:
			if clicked_card == selected_weapon:
				# Click en la misma arma - cancelar selección
				cancel_weapon_selection()
			elif clicked_card.can_be_targeted():
				# Atacar al monstruo objetivo
				attack_target(selected_weapon, clicked_card)
			elif clicked_card.can_be_selected_for_attack():
				# Cambiar a otra arma
				cancel_weapon_selection()
				select_weapon(clicked_card)

func select_weapon(weapon: Carta):
	selected_weapon = weapon
	weapon.select_for_attack()
	combat_state = CombatState.WEAPON_SELECTED
	print("Arma seleccionada para atacar")

func cancel_weapon_selection():
	if selected_weapon:
		selected_weapon.set_card_state(Carta.CardState.NORMAL)
		selected_weapon = null
	
	combat_state = CombatState.NORMAL
	print("Selección de arma cancelada")

func attack_target(weapon: Carta, target: Carta):
	if weapon.attack(target):
		print("¡Ataque exitoso!")
		# Resetear el estado de combate
		selected_weapon = null
		combat_state = CombatState.NORMAL
	else:
		print("No se pudo realizar el ataque")

func connect_card_signals(card):
	card.connect("mouseSobreCarta",on_hovered_over_card)
	card.connect("mouseFueraCarta",on_hovered_off_card)
	
func connect_combat_signals(card):
	card.connect("card_selected_for_attack", _on_card_selected_for_attack)
	card.connect("card_targeted_for_attack", _on_card_targeted_for_attack)

func _on_card_selected_for_attack(card: Carta):
	selected_weapon = card
	combat_state = CombatState.WEAPON_SELECTED

func _on_card_targeted_for_attack(attacker: Carta, target: Carta):
	attack_target(attacker, target)

func on_hovered_over_card(card):
	agrandar_carta(card,true)

func on_hovered_off_card(card):
	agrandar_carta(card,false)
		
func agrandar_carta(card,mouseSobre):
	if mouseSobre:
		card.scale = Vector2(1.05,1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1,1)
		card.z_index = 1

#permite seleccionar el area de la carta y devolver al nodo carta.
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var collider_parent = result[0].collider.get_parent()
		if collider_parent is Carta:
			return collider_parent
	return null

func reset_all_weapons():
	var all_cards = get_all_cards_in_scene()
	for card in all_cards:
		if card.data is WeaponCardData:
			card.reset_attack_ability()
	cancel_weapon_selection()
	
func block_all_weapons():
	var all_cards = get_all_cards_in_scene()
	for card in all_cards:
		if card.data is WeaponCardData:
			card.block_attack_ability()

func get_all_cards_in_scene() -> Array:
	var cards = []
	find_cards_recursive(get_tree().current_scene, cards)
	return cards
	
func find_cards_recursive(node: Node, cards_array: Array):
	if node is Carta:
		cards_array.append(node)
	for child in node.get_children():
		find_cards_recursive(child, cards_array)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	update_cursor_state()

func update_cursor_state():
	match combat_state:
		CombatState.WEAPON_SELECTED:
			# Cambiar cursor para indicar modo de ataque
			Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		CombatState.NORMAL:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
