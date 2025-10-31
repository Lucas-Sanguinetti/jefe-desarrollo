extends Carta
class_name CartaHechizo

var spell_description: Label 
var imagen_hechizo: TextureRect

signal spell_cast_requested(target)
@onready var death: AudioStreamPlayer = $Death

# Doble click
var click_timer: float = 0.0
var click_threshold: float = 0.3
var click_count: int = 0

func _initialize_references() -> void:
	super._initialize_references()
	spell_description = get_node_or_null("SpellDescript")
	imagen_hechizo = get_node_or_null("BackSprite")
	
	if not spell_description:
		push_error("CartaHechizo: Falta nodo 'Descripcion'")
	if not imagen_hechizo:
		push_error("CartaHechizo: Falta nodo 'Sprite Hechizo'")

func _setup_specific_ui() -> void:
	var spell_data = data as SpellCardData
	if not spell_data:
		push_error("CartaHechizo requiere SpellCardData")
		return
	if spell_description:
		spell_description.text = spell_data.descripcion
	if imagen_hechizo:
		imagen_hechizo.texture = spell_data.backsprite
	_apply_data_to_ui()
	update_visual_by_target_type()

func _apply_data_to_ui() -> void:
	pass

#Coloreado especial por tipo de hechizo
func update_visual_by_target_type():
	match data.target_type:
		SpellCardData.TargetType.SELF:
			modulate = Color(0.7, 1.0, 0.7)  # Verde para jugador
		SpellCardData.TargetType.ENEMY:
			modulate = Color(1.0, 0.7, 0.7)  # Rojo para enemigo

# Manejo del Doble Click
func _process(delta: float) -> void:
	super._process(delta)
	
	if click_timer > 0:
		click_timer -= delta
		if click_timer <= 0:
			click_count = 0
			
func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click() -> void:
	click_count += 1
	click_timer = click_threshold
	
	if click_count >= 2:
		_on_double_click()
		click_count = 0
		click_timer = 0

func _on_double_click() -> void:
	
	var spell_data = data as SpellCardData
	if not spell_data:
		return
	
	# Dependiendo del tipo de objetivo, manejar de forma diferente
	match spell_data.target_type:
		SpellCardData.TargetType.SELF:
			emit_signal("card_double_clicked", self)
		SpellCardData.TargetType.ENEMY:
			print("CartaHechizo: Requiere seleccionar objetivo manualmente")
			
	

#Metodo para saber si puede ser usada
func can_be_cast() -> bool:
	return current_state != CardState.CANNOT_ATTACK

#Resaltado visual al seleccionar la carta
func highlight(enabled: bool) -> void:
	if enabled:
		set_card_state(CardState.SELECTED_FOR_ATTACK)
	else:
		set_card_state(CardState.NORMAL)

func die() -> void:
	emit_signal("card_died")
	_play_death_animation()
	
	
	if parent_grid and parent_grid.has_method("update_on_card_death"):
		parent_grid.update_on_card_death(self)
		
func actLabel(label: Label) -> void:
	var spell_data = data as SpellCardData
	if not spell_data:
		return
		
	var text = "Hechizo: %s\n" % [spell_data.name]
	text += "Descripción: %s\n" % [spell_data.descripcion]
	text += "Tipo: "
	
	match spell_data.target_type:
		SpellCardData.TargetType.SELF:
			text += "Auto\n"
		SpellCardData.TargetType.ENEMY:
			text += "Enemigo\n"
	
	text += "Efecto: "
	match spell_data.effect_type:
		SpellCardData.EffectType.DAMAGE:
			text += "Daño (%d)\n" % spell_data.effect_value
		SpellCardData.EffectType.HEAL:
			text += "Curación (%d)\n" % spell_data.effect_value
	
	label.text = text
