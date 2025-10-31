extends Node2D
class_name Carta

# PROPIEDADES COMUNES
@export var data: CardData
var grid_pos: Vector2
var parent_grid: Node2D
var trait_states: Dictionary = {}

# Referencias que DEBEN existir en todas las escenas
# (Las subclases las obtienen con @onready)
var sprite: TextureRect
var area: Area2D
var resaltado: Panel

# Estados
enum CardState { NORMAL, SELECTED_FOR_ATTACK, CANNOT_ATTACK }
var current_state: CardState = CardState.NORMAL

# Estilos visuales (comunes para todas)
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat
var style_cannot_attack: StyleBoxFlat

# SEÑALES COMUNES
signal mouseSobreCarta(carta: Carta)
signal mouseFueraCarta
signal card_died
signal card_double_clicked(carta: Carta)
@warning_ignore("unused_signal")
signal card_selected_for_attack 
signal card_targeted_for_attack

# CICLO DE VIDA
func _ready() -> void:
	_initialize_references()  # Obtener nodos de la escena
	_validate_scene_structure()  # Verificar que existan los nodos necesarios
	_setup_visual_styles()
	_setup_common_ui()
	_setup_specific_ui()  # VIRTUAL - implementado por subclases
	call_deferred("connect_to_manager")

# Las subclases deben obtener sus propias referencias
func _initialize_references() -> void:
	sprite = get_node_or_null("Sprite")
	area = get_node_or_null("Area")
	# resaltado se crea dinámicamente o se busca

func _validate_scene_structure() -> void:
	if not sprite:
		push_error("%s: Falta nodo 'Sprite'" % [get_script().resource_path])
	if not area:
		push_error("%s: Falta nodo 'Area'" % [get_script().resource_path])

func setup(datos: CardData):
	self.data = datos
	_setup_specific_ui()
	_apply_data_to_ui()  # VIRTUAL


# Metodos Heredados
# Para configurar UI específica del tipo de carta
func _setup_specific_ui() -> void:
	push_warning("%s debe implementar _setup_specific_ui()" % [get_script().resource_path])

# Para aplicar datos del CardData a la UI
func _apply_data_to_ui() -> void:
	push_warning("%s debe implementar _apply_data_to_ui()" % [get_script().resource_path])

# Capacidades de combate (por defecto ninguna)
func can_be_selected_for_attack() -> bool:
	return false

func can_be_targeted() -> bool:
	return false

func can_be_double_clicked() -> bool:
	return false

# Método para recibir daño (diferente en cada tipo)
@warning_ignore("unused_parameter")
func take_damage(damage: int, attacker: Carta = null) -> void:
	push_warning("%s debe implementar take_damage()" % [get_script().resource_path])

func target_for_attack(attacker: Carta):
	if can_be_targeted():
		emit_signal("card_targeted_for_attack", attacker, self)

# MÉTODOS CONCRETOS (compartidos por todos)
func set_trait_state(key: String, value) -> void:
	trait_states[key] = value

func get_trait_state(key: String, default_value = null):
	return trait_states.get(key, default_value)

func clear_trait_state(key: String) -> void:
	trait_states.erase(key)

func clear_all_trait_states() -> void:
	trait_states.clear()

func _setup_visual_styles() -> void:
	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.TRANSPARENT
	
	style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0, 1, 0, 0.4)
	
	style_cannot_attack = StyleBoxFlat.new()
	style_cannot_attack.bg_color = Color(0.36, 0.35, 0.337, 0.0)

func _setup_common_ui() -> void:
	if sprite and data:
		sprite.texture = data.sprite
	
	# Crear panel de resaltado si no existe
	if not resaltado:
		resaltado = Panel.new()
		resaltado.name = "ResaltadoDeAtaque"
		resaltado.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resaltado.visible = false
		resaltado.position = Vector2(-42, -62)
		resaltado.size = Vector2(84, 124)
		add_child(resaltado)
	
	parent_grid = get_parent()

func set_card_state(new_state: CardState) -> void:
	current_state = new_state

func _process(_delta: float) -> void:
	_update_visual_state()

func _update_visual_state() -> void:
	if not resaltado:
		return
	
	match current_state:
		CardState.NORMAL:
			resaltado.visible = false
			modulate = Color.WHITE
			rotation_degrees = 0
		CardState.SELECTED_FOR_ATTACK:
			resaltado.visible = true
			resaltado.add_theme_stylebox_override("panel", style_selected)
		CardState.CANNOT_ATTACK:
			resaltado.visible = true
			resaltado.add_theme_stylebox_override("panel", style_cannot_attack)
			rotation_degrees = 90
			modulate = Color(0.7, 0.7, 0.7)

# Muerte común para todas las cartas
@warning_ignore("unused_parameter")
func die() -> void:
	print("La carta ha muerto: ", name)
	emit_signal("card_died")
	_play_death_animation()
	
	if parent_grid and parent_grid.has_method("update_on_card_death"):
		parent_grid.update_on_card_death(self)

func _play_death_animation() -> void:
	var tween = create_tween()
	tween.parallel().tween_property(self, "rotation", PI, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

# Efectos visuales comunes
func create_damage_effect() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func create_attack_effect(target: Carta) -> void:
	var tween = create_tween()
	var original_pos = global_position
	var target_pos = target.global_position
	
	tween.tween_property(self, "global_position", target_pos, 0.2)
	tween.tween_property(self, "global_position", original_pos, 0.2)

# Conexión con managers
func connect_to_manager() -> void:
	if not is_inside_tree():
		await tree_entered
	
	var manager = get_tree().get_first_node_in_group("CardManager")
	if manager:
		if manager.has_method("connect_combat_signals"):
			manager.connect_combat_signals(self)
		if manager.has_method("connect_card_signals"):
			manager.connect_card_signals(self)

# Señales del Area2D (manejadas igual por todos)
func _on_area_mouse_entered() -> void:
	emit_signal("mouseSobreCarta", self)

func _on_area_mouse_exited() -> void:
	emit_signal("mouseFueraCarta")

func _on_double_click():
	print("Carta: Doble click detectado en ", name)
	emit_signal("card_double_clicked", self)
	
# Sistema de traits (común)
func reset_traits_for_new_turn() -> void:
	if data and data.traits:
		for traits in data.traits:
			traits.on_turn_reset(self)

func actLabel(label: Label) -> void:
	if data:
		data.actLabel(label)
