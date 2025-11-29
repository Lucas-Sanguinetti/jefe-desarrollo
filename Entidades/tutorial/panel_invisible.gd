extends Panel

signal tutorial_click 


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("tutorial_click")
