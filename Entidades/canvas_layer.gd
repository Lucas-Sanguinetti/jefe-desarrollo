extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var timer: Timer = $Timer

func _ready():
	hide()

func action():
	show()
	color_rect.action()
	timer.start()
