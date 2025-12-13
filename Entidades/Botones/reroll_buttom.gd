extends TextureButton
class_name RerollButton

# Referencias UI
@onready var panel: Panel = $Panel if has_node("Panel") else null
@onready var titulo: Label = $Panel/Titulo if has_node("Panel/Titulo") else null
@onready var cantidad: Label = $Panel/Cantidad if has_node("Panel/Cantidad") else null
@onready var press_sound: AudioStreamPlayer = $press if has_node("press") else null

# Configuración
@export var base_cost: int = 3
@export var cost_increment: int = 3
@export var button_title: String = "Reroll"

# Colores para el panel interno
const COLOR_AVAILABLE = Color(0, 1, 0, 1.0)
const COLOR_DISABLED = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_HOVER = Color(0, 1, 0, 1.0)

# Estado
var current_cost: int = 1
var is_available: bool = true

# Señales
signal button_used(cost: int)

func _ready():
	add_to_group("RerollButton")
	current_cost = base_cost
	
	# Conectar señal del botón
	pressed.connect(_on_button_pressed)
	mouse_entered.connect(_on_button_mouse_entered)
	mouse_exited.connect(_on_button_mouse_exited)
	
	# Configurar título
	if titulo:
		titulo.text = button_title
	
	# Conectar con MoneyManager
	if MoneyManager:
		MoneyManager.monedero_cambiado.connect(_on_money_changed)
	
	# Actualizar estado inicial
	update_display()
	update_availability()

func update_display():
	if cantidad:
		cantidad.text = "x %d" % current_cost

func update_availability():
	if not MoneyManager:
		is_available = false
		disabled = true
		_update_panel_color()
		return
	
	is_available = MoneyManager.get_money() >= current_cost
	disabled = not is_available
	_update_panel_color()

func _update_panel_color():
	if not panel:
		return
	
	if not is_available:
		panel.modulate = COLOR_DISABLED
	elif is_hovered():
		panel.modulate = COLOR_HOVER
	else:
		panel.modulate = COLOR_AVAILABLE

func _on_money_changed(_new_amount: int):
	update_availability()

func _on_button_pressed():
	if not is_available:
		_shake_animation()
		return
	
	# Pagar el costo
	MoneyManager.perderMonedas(current_cost)
	
	# Reproducir sonido
	if press_sound and press_sound.stream:
		press_sound.play()
	
	# Emitir señal
	emit_signal("button_used", current_cost)
	
	# Aumentar costo
	current_cost += cost_increment
	update_display()
	update_availability()
	
	print("RerollButton: Usado - Nuevo costo: %d" % current_cost)

func _on_button_mouse_entered():
	if is_available and panel:
		panel.modulate = COLOR_HOVER

func _on_button_mouse_exited():
	_update_panel_color()

func reset_for_new_turn():
	current_cost = base_cost
	update_display()
	update_availability()
	print("RerollButton: Reseteado a costo: %d" % base_cost)

func _shake_animation():
	if not panel:
		return
	
	var original_pos = panel.position
	var tween = create_tween()
	tween.tween_property(panel, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(panel, "position", original_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(panel, "position", original_pos, 0.05)

func setup(title: String, initial_cost: int, increment: int = 1):
	button_title = title
	base_cost = initial_cost
	cost_increment = increment
	current_cost = base_cost
	
	if titulo:
		titulo.text = title
	
	update_display()
	update_availability()
