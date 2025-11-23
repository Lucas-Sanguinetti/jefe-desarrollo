extends Carta
class_name CartaMonstruo


var vida_label: Label
var ataque_label: Label
var traits_label: Label
var niveles_sprite: Sprite2D 
var element_sprite: TextureRect
var backsprite_sprite: TextureRect

var backsprite: Texture2D
var element:Texture2D
var hp_actual:int
var ataque:int
var max_hp:int
var nivel:int 
var rasgos:Array

var death_sound: AudioStream

var is_targetable: bool = false
@onready var death: AudioStreamPlayer = $Death


func _initialize_references() -> void:
	super._initialize_references()
	vida_label = get_node_or_null("Vida")
	ataque_label = get_node_or_null("Ataque")
	traits_label = get_node_or_null("MonsterTraits")
	niveles_sprite = get_node_or_null("Niveles")
	element_sprite = get_node_or_null("Element")
	backsprite_sprite = get_node_or_null("BackSprite")
	
	# Validación
	if not vida_label:
		push_error("CartaMonstruo: Falta nodo 'Vida'")
	if not ataque_label:
		push_error("CartaMonstruo: Falta nodo 'Ataque'")
	if not traits_label:
		push_error("CartaMonstruo: Falta nodo 'MonsterTraits'")
	if not niveles_sprite:
		push_error("CartaArma: Falta nodo 'Niveles'")

func _setup_specific_ui() -> void:
	var monster_data = data as MonsterCardData
	if not monster_data:
		push_error("CartaMonstruo requiere MonsterCardData")
		return
	
	hp_actual = monster_data.hp
	ataque = monster_data.attack
	max_hp = monster_data.hp
	nivel = monster_data.nivel
	rasgos = monster_data.traits
	element = monster_data.element
	backsprite = monster_data.backsprite
	death_sound = monster_data.death
	if traits_label:
		traits_label.text = _get_traits_text(monster_data)
	if niveles_sprite:
		niveles_sprite.set_nivel(nivel)
	if ataque_label:
		ataque_label.text = str(ataque)
	if element_sprite:
		element_sprite.texture = element
	if backsprite_sprite:
		backsprite_sprite.texture = backsprite
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


# UTILIDADES PRIVADAS
func _get_traits_text(monster_data: MonsterCardData) -> String:
	var texto: String = ""
	for traits in monster_data.traits:
		texto += "* %s\n" % [traits.trait_name]
	return texto

#Utilidad de info
func actLabel(label: Label) -> void:
	var text = "Ataque: %d\n" % [ataque]
	text += "Vida: %d\n" % [hp_actual]
	# Agregar traits
	if not rasgos.is_empty():
		for rasgo in rasgos:
			if rasgo is Endurecer:
				text += "* %s " % [rasgo.trait_name]
				text += "  %s\n" % [rasgo.resistencia]
			else:
				text += "* %s\n" % [rasgo.trait_name]
			text += " %s\n" % [rasgo.trait_description]
	else:
		text += "Sin traits\n"
		
	label.text = text
