extends CanvasLayer

@onready var color_rect: ColorRect = $Damage
@onready var timer: Timer = $Timer
@onready var curacion: ColorRect = $Curacion
@onready var curar_timer: Timer = $CurarTimer

func _ready():
	hide()
	
func damage():
	color_rect.visible = true
	curacion.visible = false
	show()
	color_rect.action()
	timer.start()

func curar():
	curacion.visible = true
	color_rect.visible = false
	show()
	curacion.action()
	curar_timer.start()
