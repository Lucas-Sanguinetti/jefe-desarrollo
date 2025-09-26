extends Node2D

signal vida_cambiada(nueva_vida)

var vida: int = 50 

func set_vida(value):
	vida = clamp(value, 0, 50)
	emit_signal("vida_cambiada", vida)

func gainLife(cant: int ):
	set_vida(vida + cant)
	
func looseLife(cant: int):
	set_vida(vida - cant)

#Debug
func life():
	print(vida)
