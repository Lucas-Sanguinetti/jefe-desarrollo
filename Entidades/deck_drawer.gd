extends Node
## esto se tiene que transformar a un state machine que pida al mazo de mosntruos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("DeckMonsterSpawner")

func size():
	var turno = TurnManager.get_current_turn()
	match turno:
		_ when turno < 11:
			return MonsterDeck.size1()
		_ when turno >= 11:
			return MonsterDeck.size2()

func draw_resucitado():
	var turno = TurnManager.get_current_turn()
	match turno:
		_ when turno < 11:
			return MonsterDeck.draw1()
		_ when turno >= 11:
			return MonsterDeck.draw2()

func draw():
	var turno = TurnManager.get_current_turn()
	match turno:
		_ when turno < 11:
			return MonsterDeck.draw1()
		_ when turno < 20:
			return MonsterDeck.draw2()
		_ when turno == 20:
			return MonsterDeck.draw3()
		_ when turno > 20:
			return
	
	
