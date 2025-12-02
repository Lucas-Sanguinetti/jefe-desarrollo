extends Node2D

signal vida_cambiada(nueva_vida)

var vida: int = 50 
var vidaMaxima:int = 50

func set_vida(value):
	vida = clamp(value, 0, 50)
	emit_signal("vida_cambiada", vida)

func gainLife(cant: int ):
	if TurnManager.can_player_heal():
		set_vida(vida + cant)
	
func looseLife(cant: int):
	set_vida(vida - cant)

func get_maxLife():
	return vidaMaxima

func get_life():
	return vida

#Debug
func life():
	print(vida)

func reset():
	vida = vidaMaxima
