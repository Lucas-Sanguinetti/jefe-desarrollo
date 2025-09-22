extends Node

##se van usar tres arrays distintos para poder diferenciar de que parte del mazo se va a sacar un monstro
##el monster spawner va a tener un state que vaya con los turnos, y ese state saca del mazo correspondiente
var wave1Monsters:Array = []
#var wave2Monsters:Array = []
#var wave3Monsters:Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#deben llenarse los mazos con las cartas guardadas en los resourses
	
	#luego se mezclan los mazos
	wave1Monsters.shuffle()
	#wave2Monsters.shuffle()
	#wave3Monsters.shuffle()

##funcion para el state
func draw1():
	return wave1Monsters[0]

##funcion para el state	
func draw2():
	pass
	#return wave2Monsters[0]

##funcion para el state
func draw3():
	pass
	#return wave3Monsters[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
