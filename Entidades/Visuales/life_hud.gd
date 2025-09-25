extends Node2D

@onready var label = $Vida
@onready var sprite = $Sprite2D

func _ready():
	LifeManager.connect("vida_cambiada", Callable(self, "_on_vida_cambiada"))
	# mostrar estado inicial
	_on_vida_cambiada(LifeManager.vida)

func _on_vida_cambiada(valor: int):
	label.text = str(valor)
	
	#Por si cambiamos la imagen en reflejo de la vida 
	#if valor > 70:
	#elif valor > 30:
	#else:
