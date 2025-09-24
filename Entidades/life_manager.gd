extends Node2D


@onready var vida: Label = $Vida


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerLife.restante.restante = 50
	vida.text = str(PlayerLife.restante)

func gainLife(life: int ):
	PlayerLife.restante += life
	vida.text = str(PlayerLife.restante)
	
func looseLife(life: int):
	PlayerLife.restante -= life
	vida.text = str(PlayerLife.restante)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
