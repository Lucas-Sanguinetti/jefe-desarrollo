extends Node
## esto se tiene que transformar a un state machine que pida al mazo de mosntruos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func draw():
	return MonsterDeck.draw1()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
