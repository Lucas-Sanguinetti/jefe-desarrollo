# CardSlot.gd
extends Node2D
class_name CardSlot

@export var is_occupied: bool = false
var current_card: Node2D = null

func place_card(card: Node2D) -> bool:
	if is_occupied:
		return false
	
	current_card = card
	is_occupied = true
	
	# Mover la carta a la posición del slot
	card.reparent(self)
	card.position = Vector2.ZERO
	
	return true

func remove_card() -> Node2D:
	if not is_occupied:
		return null
	
	var card = current_card
	current_card = null
	is_occupied = false
	
	return card
