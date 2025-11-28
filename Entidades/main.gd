extends Node

@onready var pause_menu: PauseMenu = $PauseMenu
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if pause_menu:
		pause_menu.resume_pressed.connect(_on_pause_resume)
		pause_menu.restart_pressed.connect(_on_pause_restart)
		pause_menu.main_menu_pressed.connect(_on_pause_main_menu)


func _on_pause_resume():
	pass
	
func _on_pause_restart():
	pass
	
func _on_pause_main_menu():
	pass
