extends Label

@onready var cambio_de_vida_timer: Timer = $CambioDeVidaTimer 

func _ready(): 
	hide() 
	
func winLife(life): 
	show() 
	add_theme_color_override("font_color", Color("#00FF00")) 
	text = "+" + str(life) 
	cambio_de_vida_timer.start() 
	
func loseLife(life): 
	show() 
	add_theme_color_override("font_color", Color("#FF0000")) 
	text = "-" + str(life) 
	cambio_de_vida_timer.start() 
	
func _on_cambio_de_vida_timer_timeout() -> void: 
	hide()
