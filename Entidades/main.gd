extends Node

@onready var turn_button = $Button
@onready var turn_label = $CanvasLayer/ContadorTurno
var current_turn = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)

func _on_turn_button_pressed():
	current_turn += 1
	turn_label.text = "Turno: " + str(current_turn)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
