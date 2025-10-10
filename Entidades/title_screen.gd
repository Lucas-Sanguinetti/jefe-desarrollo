extends PanelContainer


func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Entidades/Game.tscn")


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://Entidades/tutorial/Tutorial.tscn")
