extends Node2D

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print(raycast_check_for_card())
			
		else:
			print("suelto izquierda")

func connect_card_signals(card):
	card.connect("mouseSobreCarta",on_hovered_over_card)
	card.connect("mouseFueraCarta",on_hovered_off_card)
	

func on_hovered_over_card(card):
	agrandar_carta(card,true)

func on_hovered_off_card(card):
	agrandar_carta(card,false)
		
func agrandar_carta(card,mouseSobre):
	if mouseSobre:
		card.scale = Vector2(1.05,1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1,1)
		card.z_index = 1

#permite seleccionar el area de la carta y devolver al nodo carta.
func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
