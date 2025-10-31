extends PanelContainer

@onready var jugar: Button = $VBoxContainer/Jugar
@onready var tutorial: Button = $VBoxContainer/Tutorial
@onready var timer_game: Timer = $TimerGame
@onready var timer_tutorial: Timer = $TimerTutorial

func _on_jugar_pressed() -> void:
	jugar.pressPlay()
	timer_game.start()

func _on_tutorial_pressed() -> void:
	tutorial.pressPlay()
	timer_tutorial.start()
	
func _on_timer_game_timeout() -> void:
	get_tree().change_scene_to_file("res://Entidades/Game.tscn")


func _on_timer_tutorial_timeout() -> void:
	get_tree().change_scene_to_file("res://Entidades/tutorial/Tutorial.tscn")
