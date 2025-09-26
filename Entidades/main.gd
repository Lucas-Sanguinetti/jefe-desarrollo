extends Node

@onready var turn_button = $CanvasLayer/PasarTurno
@onready var turn_label = $CanvasLayer/ContadorTurno
@onready var card_manager = $CardManager
var current_turn = 1

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)

func _on_turn_button_pressed():
	current_turn += 1
	turn_label.text = "Turno: " + str(current_turn)
	
	if LifeManager.vida > 0:
		if card_manager:
			card_manager.reset_all_weapons()
	else:
		if card_manager:
			card_manager.block_all_weapons()
	print("Nuevo turno iniciado. Todas las armas pueden atacar nuevamente.")

func _process(delta: float) -> void:
	pass
