extends Node

var wave1Monsters:Array = [MonsterCardData]
var wave2Monsters:Array = [MonsterCardData]
@export var tutorial_monster: MonsterCardData 
@export var monster_data_cards: Array[MonsterCardData] 
@export var monster_bosses_data: Array[MonsterCardData] 
var monstruo_tutoria_reset 
var monstruos_reset
var bosses_reset 
 
func _ready() -> void:
	
	wave1Monsters = filtrarMonstruos(1,3,monster_data_cards)
	wave2Monsters = filtrarMonstruos(4,5,monster_data_cards)
	
	#luego se mezclan los mazos
	wave1Monsters.shuffle()
	wave2Monsters.shuffle()
	monster_bosses_data.shuffle()
	
	monstruo_tutoria_reset = tutorial_monster.duplicate(true)
	monstruos_reset = monster_data_cards.duplicate(true)
	bosses_reset = monster_bosses_data.duplicate(true)

func draw1():
	var monster:MonsterCardData = wave1Monsters[0]
	wave1Monsters.remove_at(0)
	return monster

func draw2():
	var monster:MonsterCardData = wave2Monsters[0]
	wave2Monsters.remove_at(0)
	return monster

func draw3():
	var monster:MonsterCardData = monster_bosses_data[0]
	monster_bosses_data.remove_at(0)
	return monster
	
##funcion para el state
func drawTutorial():
	return tutorial_monster

func size():
	return monster_data_cards.size()

func reset():
	tutorial_monster = monstruo_tutoria_reset
	monster_data_cards.clear()
	monster_data_cards.append_array(monstruos_reset)
	monster_bosses_data.clear()
	monster_bosses_data.append_array(bosses_reset)
	
	wave1Monsters = filtrarMonstruos(1,3,monster_data_cards)
	wave2Monsters = filtrarMonstruos(4,5,monster_data_cards)
	
	wave1Monsters.shuffle()
	wave2Monsters.shuffle()
	monster_bosses_data.shuffle()

func filtrarMonstruos(minLvl:int, maxLvl:int, lista:Array):
	var monstruos = lista.filter(func(m):
		return m.nivel >= minLvl and m.nivel <= maxLvl
	)
	return monstruos
