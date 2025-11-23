extends Node2D
class_name MonsterSpawner

@onready var grid_monstruos: Node2D = $MonsterGrid
@onready var deck_drawer: Node = $DeckDrawer
@onready var turn_button = $"../CanvasLayer/PasarTurno"

var cards_per_turn: int = 1  # Cantidad de cartas por turno


func draw():
	var r = sin_monstruos()
	place_monster(r)

func sin_monstruos() -> int:
	var cant_monsters = grid_monstruos.get_all_monsters().size()
	if cant_monsters < 1:
		return 2
	return 1

func place_monster(repeticiones:int):
	var monster:MonsterCardData
	for i in repeticiones:
		monster = deck_drawer.draw()
		if monster:
			grid_monstruos.invoke_random_piece(monster)

	
