extends Carta
class_name CartaHechizo

#UI
var spell_description: Label 
var imagen_hechizo: TextureRect
var one_time_indicator: Panel #Agregar el nuevo panel para este efecto 

#Estados
var is_used: bool = false  # Para hechizos de uso único
var cost_paid: bool = false  # Si ya se pagó el coste

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
	one_time_indicator = get_node_or_null("OneTimeIndicator")
	
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
	var spell_data = data as SpellCardData
	if not spell_data:
		return
	
	# Mostrar indicador de uso único
	if one_time_indicator:
		one_time_indicator.visible = spell_data.one_time_use
		
		if spell_data.one_time_use:
			# Estilo especial: borde dorado brillante
			var style = StyleBoxFlat.new()
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color(1.0, 0.84, 0.0, 1.0)  # Dorado
			style.set_border_width_all(3)
			one_time_indicator.add_theme_stylebox_override("panel", style)

func can_be_cast() -> bool:
	if is_used:
		return false
	var spell_data = data as SpellCardData
	# Verificar coste de monedas
	if spell_data.cost_money > 0 and MoneyManager.get_money() < spell_data.cost_money:
		return false
	
	return true

func mark_as_used():
	is_used = true
	set_card_state(CardState.CANNOT_ATTACK)

func pay_cost():
	if cost_paid:
		return
	
	var spell_data = data as SpellCardData
	if not spell_data:
		return
	
	if spell_data.cost_money > 0:
		MoneyManager.perderMonedas(spell_data.cost_money)
		cost_paid = true

#Coloreado especial por tipo de hechizo
func update_visual_by_target_type():
	var spell_data = data as SpellCardData
	if not spell_data:
		return
	
	# Colorear según categoría
	match spell_data.effect_category:
		SpellCardData.EffectCategory.DAMAGE:
			modulate = Color(1.0, 0.7, 0.7)  # Rojo
		SpellCardData.EffectCategory.HEALING:
			modulate = Color(0.7, 1.0, 0.7)  # Verde
		SpellCardData.EffectCategory.BUFF:
			modulate = Color(0.7, 0.7, 1.0)  # Azul
		SpellCardData.EffectCategory.UTILITY:
			modulate = Color(1.0, 1.0, 0.7)  # Amarillo
		SpellCardData.EffectCategory.SUMMON:
			modulate = Color(0.8, 0.5, 1.0)  # Púrpura
		SpellCardData.EffectCategory.ECONOMY:
			modulate = Color(1.0, 0.84, 0.0)  # Dorado

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
	
	print("CartaHechizo: Doble click en '%s'" % spell_data.name)
	emit_signal("card_double_clicked", self)
			
	

#Metodo para saber si puede ser usada

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
	text += "Categoría: %s\n" % [spell_data.get_category_string()] #Preguntar a lucas
	text += "Objetivo: %s\n" % [spell_data.get_target_type_string()]
	text += "\n"
	text += "%s\n" % [spell_data.descripcion]
	# Info de valores
	if spell_data.effect_value != 0:
		text += "Valor: %d\n" % [spell_data.effect_value]
	if spell_data.secondary_value != 0:
		text += "Valor 2: %d\n" % [spell_data.secondary_value]
	if spell_data.tertiary_value != 0:
		text += "Valor 3: %d\n" % [spell_data.tertiary_value]
	# Info de restricciones
	if spell_data.one_time_use:
		text += "\n[USO ÚNICO - No vuelve al mazo]"
	if spell_data.cost_money > 0:
		text += "\nCoste: %d monedas" % [spell_data.cost_money]
	# Info de efecto personalizado
	if spell_data.effect_id != "":
		text += "\n[Efecto: %s]" % [spell_data.effect_id]
	
	label.text = text
