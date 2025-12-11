extends Node2D

@onready var label = $Vida
@onready var sprite = $Sprite2D

# animacion
var shaking := false
var shake_strength := 2.0
var original_position := Vector2.ZERO

func _ready():
	LifeManager.connect("vida_cambiada", Callable(self, "_on_vida_cambiada"))
	original_position = position
	_on_vida_cambiada(LifeManager.vida)

func _on_vida_cambiada(valor: int):
	label.text = str(valor)
	
	#fuerza de la vibracion
	if valor <= 10:
		shake_strength = 3.0
	else:
		shake_strength = 1.5
		
	if valor <= 20:
		shaking = true
	else:
		shaking = false
		position = original_position   # vuelve a su lugar

func _process(delta):
	if shaking:
		position = original_position + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
