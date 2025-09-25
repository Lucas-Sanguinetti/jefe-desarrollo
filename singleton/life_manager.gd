extends Node2D

@export var vidaRestante:int = 50
@onready var vida: Label = $Vida


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize()
	
	
func initialize():
	vidaRestante = 50
	actualizarVida(vidaRestante)

func gainLife(life: int ):
	vidaRestante += life
	actualizarVida(vidaRestante)
	
func looseLife(life: int):
	vidaRestante -= life
	actualizarVida(vidaRestante)

func actualizarVida(vidaRestante: int):
	vida.text = str(vidaRestante)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
