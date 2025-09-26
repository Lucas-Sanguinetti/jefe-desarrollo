extends Node

##se van usar tres arrays distintos para poder diferenciar de que parte del mazo se va a sacar un monstro
##el monster spawner va a tener un state que vaya con los turnos, y ese state saca del mazo correspondiente
var wave1Monsters:Array = []
#var wave2Monsters:Array = []
#var wave3Monsters:Array = []

@export var monster1:MonsterCardData
@export var monster2:MonsterCardData
 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#deben llenarse los mazos con las cartas guardadas en los resourses
	wave1Monsters.push_back(monster1)
	wave1Monsters.push_back(monster2)
	
	#luego se mezclan los mazos
	print(wave1Monsters)
	#wave2Monsters.shuffle()
	#wave3Monsters.shuffle()

##funcion para el state
func draw1():
	print("robe una carta")
	var monster:MonsterCardData = wave1Monsters[0]
	wave1Monsters.remove_at(0)
	return monster

##funcion para el state	
func draw2():
	pass
	#var monster:Carta = wave1Monsters[0]
	#wave1Monsters.remove_at(0)
	#return monster

##funcion para el state
func draw3():
	pass
	#var monster:Carta = wave1Monsters[0]
	#wave1Monsters.remove_at(0)
	#return monster


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
