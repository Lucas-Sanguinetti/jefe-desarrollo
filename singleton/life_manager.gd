extends Node2D

@export var vidaRestante = 50
@onready var vida: Label = $Vida


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vidaRestante = 50
	vida.text = str(vidaRestante)

func gainLife(life: int ):
	vidaRestante += life
	vida.text = str(vidaRestante)
	
func looseLife(life: int):
	vidaRestante -= life
	vida.text = str(vidaRestante)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
