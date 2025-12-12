extends Carta
class_name CartaMonstruo
#Visuales
var vida_label: Label
var ataque_label: Label
var traits_label: Label
var niveles_sprite: Sprite2D 
var element_sprite: TextureRect
var backsprite_sprite: TextureRect
var death_preview: TextureRect
var container: VBoxContainer 
@onready var small_font := preload("uid://jv50m8p7i6as")
# Datos 
var element: MonsterCardData.ElementType
var hp_actual:int
var ataque:int
var max_hp:int
var nivel:int 
var rasgos:Array
#Sonidos
var death_sound: AudioStream
@onready var death: AudioStreamPlayer = $Death
#Signals & States
var is_targetable: bool = false
signal boss_died()

func _initialize_references() -> void:
	super._initialize_references()
	vida_label = get_node_or_null("Vida")
	ataque_label = get_node_or_null("Ataque")
	container = get_node_or_null("VBoxContainer")
	niveles_sprite = get_node_or_null("Niveles")
	element_sprite = get_node_or_null("Element")
	backsprite_sprite = get_node_or_null("BackSprite")
	death_preview = get_node_or_null("DeathPreview") 
	
	# Validación
	if not vida_label:
		push_error("CartaMonstruo: Falta nodo 'Vida'")
	if not ataque_label:
		push_error("CartaMonstruo: Falta nodo 'Ataque'")
	if not container:
		push_error("CartaMonstruo: Falta nodo 'VBoxContainer'")
	if not niveles_sprite:
		push_error("CartaArma: Falta nodo 'Niveles'")
	if not death_preview:
		push_error("CartaMonstruo: Falta nodo 'DeathPreview'")

func _setup_specific_ui() -> void:
	var monster_data = data as MonsterCardData
	if not monster_data:
		push_error("CartaMonstruo requiere MonsterCardData")
		return
	
	hp_actual = monster_data.hp
	ataque = monster_data.attack
	max_hp = monster_data.hp
	element = monster_data.element_type
	nivel = monster_data.nivel
	rasgos = monster_data.traits
	death_sound = monster_data.death
	if container:
		display_traits()
	if niveles_sprite:
		niveles_sprite.set_nivel(nivel)
	if ataque_label:
		ataque_label.text = str(ataque)
	if element_sprite:
		element_sprite.texture = monster_data.element
	if backsprite_sprite:
		backsprite_sprite.texture = monster_data.backsprite
	_apply_data_to_ui()

func _apply_data_to_ui() -> void:
	if vida_label:
		vida_label.text = str(hp_actual)

func can_be_targeted() -> bool:
	for rasgo in rasgos:
		if rasgo is Valiente:
			return true
	
	var grid = parent_grid
	if grid and grid is MonsterGrid:
		var pos = grid_pos
		var x = int(pos.x)
		var y = int(pos.y)
		
		var directions = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
		
		for dir in directions:
			var check_x = x + int(dir.x)
			var check_y = y + int(dir.y)
			
			if check_x < 0 or check_x >= grid.GRID_SIZE or check_y < 0 or check_y >= grid.GRID_SIZE:
				continue
			
			var adjacent_card = grid.grid[check_x][check_y]
			if adjacent_card and adjacent_card.data is MonsterCardData:
				# Verificar si el adyacente tiene Valiente
				for adj_trait in adjacent_card.data.traits:
					if adj_trait is Valiente:
						print("DEBUG: %s está protegido por Valiente en [%d,%d]" % [name, check_x, check_y])
						return false
	for rasgo in rasgos:
		if rasgo is Escurridizo:
			return rasgo.can_be_targeted_override(self)
			
	return true 


func take_damage(damage: int, attacker: Carta = null) -> void:
	
	# Aplicar reducción de traits
	if attacker:
		for rasgo in rasgos:
			damage = rasgo.take_damage(attacker, self, damage)
	
	hp_actual -= damage
	_apply_data_to_ui()  # Actualizar vida en pantalla
	if parent_grid and parent_grid.has_node("MonsterGridVisuals"):
		var visuals = parent_grid.get_node("MonsterGridVisuals")
		visuals.show_damage_effect(self)
	else:
		create_damage_effect()
	
	if hp_actual <= 0:
		die()
		


func die() -> void:
	print("CartaMonstruo: %s ha muerto" % [name])
	death.playSound(death_sound)
	await get_tree().create_timer(0.5).timeout
	MoneyManager.ganarMonedas(nivel)
	
	for rasgo in rasgos:
		if rasgo is Renacer:
			rasgo.on_monster_death(self)
	emit_signal("card_died")
	
	if data.boss:
		emit_signal("boss_died")
	
	if parent_grid and parent_grid.has_node("MonsterGridVisuals"):
		var visuals = parent_grid.get_node("MonsterGridVisuals")
		var tween = visuals.animate_death(self)
		tween.tween_callback(queue_free)
	else:
		_play_death_animation()  # Fallback del padre

#UTILIDADES DE HECHIZOS
func set_targetable(enabled: bool):
	is_targetable = enabled
	if resaltado:
		if enabled:
			resaltado.visible = true
			resaltado.add_theme_stylebox_override("panel", style_selected)
		else:
			resaltado.visible = false

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Verificar si la mano está esperando selección de objetivo
		var hand = get_tree().get_first_node_in_group("Hand")
		if hand and hand.has_method("is_waiting_for_target") and hand.is_waiting_for_target():
			if can_be_targeted():
				hand.target_selected(self)
			return


# UTILIDADES 
func calculate_damage_from(weapon: CartaArma) -> int:
	if not weapon or not weapon is CartaArma:
		return 0
	
	# Obtener el daño del arma 
	var incoming_damage = weapon.calculate_total_damage_to(self)
	
	# Aplicar reducción de traits del monstruo
	for rasgo in rasgos:
		incoming_damage = rasgo.take_damage(weapon, self, incoming_damage)
	
	return incoming_damage

# Verifica si el arma puede matar a este monstruo de un golpe
func would_be_killed_by(weapon: CartaArma) -> bool:
	if not weapon or not weapon is CartaArma:
		return false
	
	# Si el monstruo está protegido por otros (Valiente, Escurridizo), no puede morir
	if not can_be_targeted():
		return false
	
	var total_damage = calculate_damage_from(weapon)
	return total_damage >= hp_actual

# Muestra u oculta el indicador de muerte
@warning_ignore("shadowed_variable_base_class")
func show_death_preview(show: bool) -> void:
	if death_preview:
		death_preview.visible = show

#Utilidad de info
func actLabel(label: Label) -> void:
	var text = "Ataque: %d\n" % [ataque]
	text += "Vida: %d\n" % [hp_actual]
	text += "Recompensa: %d monedas\n" % [nivel]
	# Agregar traits
	if not rasgos.is_empty():
		for rasgo in rasgos:
			if rasgo is Endurecer:
				text += "%s : " % [rasgo.trait_name]
				text += "  %s\n" % [rasgo.resistencia]
			else:
				text += "%s :\n" % [rasgo.trait_name]
			text += " %s\n" % [rasgo.trait_description]
	else:
		text += "Sin pasivas\n"
		
	label.text = text
	
func display_traits():
	# Limpiar traits previos
	for child in container.get_children():
		child.queue_free()

	# Añadir traits de arma
	for rasgo in rasgos:
		add_trait_to_container(rasgo.trait_name)


func add_trait_to_container(text: String):
	if not container:
		return
	
	# Crear el panel contenedor
	var panel := PanelContainer.new()  # Usar PanelContainer en lugar de Panel
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Crear el StyleBox para el fondo
	var style := StyleBoxFlat.new()
	
	# Opción B — usar un color más desaturado (recomendado):
	var base_color = get_element_color()
	style.bg_color = base_color.lerp(Color.GRAY, 0.30)

	# Bordes rectos (sin radio)
	style.set_corner_radius_all(0)

	# Borde blanco muy fino
	style.border_color = Color.WHITE
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	# Márgenes internos
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2

	panel.add_theme_stylebox_override("panel", style)
	
	# Crear el label
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_vertical = Control.SIZE_EXPAND
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font", small_font)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.WHITE)  # Texto blanco
	
	# Agregar label al panel
	panel.add_child(label)
	
	# Agregar panel al container
	container.add_child(panel)

func get_element_color() -> Color:
	match element:
		WeaponCardData.ElementType.FIRE:
			return Color(1.0, 0.0, 0.0) # Rojo
		WeaponCardData.ElementType.ELECTRIC:
			return Color(1.0, 1.0, 0.0) # Amarillo
		WeaponCardData.ElementType.NATURE:
			return Color(0.0, 0.4, 0.0) # Verde oscuro
		WeaponCardData.ElementType.WIND:
			return Color(0.6, 0.9, 0.6) # Verde claro / agua
		WeaponCardData.ElementType.POISON:
			return Color(0.7, 1.0, 0.0) # Verde lima
		WeaponCardData.ElementType.DARK:
			return Color(0.2, 0.0, 0.3) # Violeta oscuro
		WeaponCardData.ElementType.TECH:
			return Color(0.5, 0.5, 0.5) # Gris
		WeaponCardData.ElementType.WATER:
			return Color(0.0, 0.3, 1.0) # Azul
		WeaponCardData.ElementType.ICE:
			return Color(0.5, 0.8, 1.0) # Celeste
		WeaponCardData.ElementType.EARTH:
			return Color(0.4, 0.26, 0.13) # Marrón
		_:
			return Color(1, 1, 1) # Fallback
	
func get_display_resource() -> Resource:
	var copy = data.duplicate()
	
	copy.attack = ataque
	copy.hp = hp_actual

	return copy
