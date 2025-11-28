extends CanvasLayer
class_name PauseMenu

# Referencias a nodos
@onready var panel_container: PanelContainer = $PanelContainer

@onready var master_slider: HSlider = $PanelContainer/VBoxContainer/MasterVolume/HBoxContainer/MasterSlider
@onready var master_label: Label = $PanelContainer/VBoxContainer/MasterVolume/HBoxContainer/MasterValue

@onready var music_slider: HSlider = $PanelContainer/VBoxContainer/MusicVolume/HBoxContainer/MusicSlider
@onready var music_label: Label = $PanelContainer/VBoxContainer/MusicVolume/HBoxContainer/MusicValue

@onready var effects_slider: HSlider = $PanelContainer/VBoxContainer/EffectsVolume/HBoxContainer/EffectsSlider
@onready var effects_label: Label = $PanelContainer/VBoxContainer/EffectsVolume/HBoxContainer/EffectsValue

@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PanelContainer/VBoxContainer/RestartButton
@onready var main_menu_button: Button = $PanelContainer/VBoxContainer/MainMenuButton

# Señales
signal resume_pressed
signal restart_pressed
signal main_menu_pressed

# Estado
var is_paused: bool = false

func _ready():
	# Esconder el menú al inicio
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cargar volúmenes guardados
	_load_audio_settings()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	
	if is_paused:
		show()
		get_tree().paused = true
		resume_button.grab_focus()
	else:
		hide()
		get_tree().paused = false

func _on_master_slider_value_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	master_label.text = str(int(value)) + "%"
	_save_audio_settings()

func _on_music_slider_value_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)
	music_label.text = str(int(value)) + "%"
	_save_audio_settings()

func _on_effects_slider_value_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"), db)
	effects_label.text = str(int(value)) + "%"
	_save_audio_settings()

func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80
	return 20 * log(linear) / log(10)

func _on_resume_button_pressed() -> void:
	emit_signal("resume_pressed")
	toggle_pause()

func _on_restart_button_pressed() -> void:
	
	get_tree().paused = false
	hide()
	emit_signal("restart_pressed")
	# Enganchar logica de reinicio

func _on_main_menu_button_pressed() -> void:
	
	get_tree().paused = false
	hide()
	emit_signal("main_menu_pressed")

	# Aquí es donde enganchas tu lógica para volver al menú

func _save_audio_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "effects", effects_slider.value)
	config.save("user://audio_settings.cfg")

func _load_audio_settings():
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err == OK:
		master_slider.value = config.get_value("audio", "master", 100)
		music_slider.value = config.get_value("audio", "music", 100)
		effects_slider.value = config.get_value("audio", "effects", 100)
	else:
		# Valores por defecto
		master_slider.value = 100
		music_slider.value = 100
		effects_slider.value = 100
