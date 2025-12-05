extends PanelContainer

@onready var jugar: Button = $VBoxContainer/Jugar
@onready var tutorial: Button = $VBoxContainer/Tutorial
@onready var timer_game: Timer = $TimerGame
@onready var timer_tutorial: Timer = $TimerTutorial
@onready var main_menu_theme: AudioStreamPlayer = $MainMenuTheme
@onready var option_layer: CanvasLayer = $optionLayer

func _ready():
	main_menu_theme.play()
	option_layer.resume_pressed.connect(_on_pause_resume)

func _on_jugar_pressed() -> void:
	jugar.pressPlay()
	timer_game.start()

func _on_tutorial_pressed() -> void:
	tutorial.pressPlay()
	timer_tutorial.start()
	
func _on_timer_game_timeout() -> void:
	get_tree().change_scene_to_file("res://Entidades/game.tscn")


func _on_timer_tutorial_timeout() -> void:
	get_tree().change_scene_to_file("res://Entidades/tutorial/tutorial.tscn")



func _on_opciones_pressed() -> void:
	option_layer.visible = true

func _on_pause_resume():
	pass
