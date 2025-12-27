extends Node
## esto se tiene que transformar a un state machine que pida al mazo de mosntruos


var low_level_turn = TurnManager.get_limit_low_level_turn()
var high_level_turn = TurnManager.get_limit_high_level_turn()

func _ready() -> void:
	add_to_group("DeckMonsterSpawner")

func size():
	var turno = TurnManager.get_current_turn()
	match turno:
		_ when turno < low_level_turn:
			return MonsterDeck.size1()
		_ when turno >= low_level_turn:
			return MonsterDeck.size2()

func draw_resucitado():
	var turno = TurnManager.get_current_turn()
	match turno:
		_ when turno < low_level_turn:
			return MonsterDeck.draw1()
		_ when turno >= low_level_turn:
			return MonsterDeck.draw2()

func draw():
	var turno = TurnManager.get_current_turn()
	match turno:
		_ when turno < low_level_turn:
			return MonsterDeck.draw1()
		_ when turno < high_level_turn:
			return MonsterDeck.draw2()
		_ when turno == high_level_turn:
			return MonsterDeck.draw3()
		_ when turno > high_level_turn:
			return
	
	
