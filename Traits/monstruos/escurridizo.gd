extends TraitBase
class_name Escurridizo

#func _init():
	#trait_name = "Escurridizo"
	#trait_description = "No puede ser atacado si tiene monstruos adyacentes sin Escurridizo"

# Este método se llama desde CartaMonstruo.can_be_targeted()
func can_be_targeted_override(monster: CartaMonstruo) -> bool:
	var grid = monster.parent_grid
	if not grid or not grid is MonsterGrid:
		return true  # Si no está en grid, puede ser atacado
	
	var pos = monster.grid_pos
	var x = int(pos.x)
	var y = int(pos.y)
	
	# Direcciones adyacentes (arriba, abajo, izquierda, derecha)
	var directions = [
		Vector2(0, -1),  # Arriba
		Vector2(0, 1),   # Abajo
		Vector2(-1, 0),  # Izquierda
		Vector2(1, 0)    # Derecha
	]
	
	var has_adjacent_without_escurridizo = false
	
	for dir in directions:
		var check_x = x + int(dir.x)
		var check_y = y + int(dir.y)
		
		# Verificar límites del grid
		if check_x < 0 or check_x >= grid.GRID_SIZE or check_y < 0 or check_y >= grid.GRID_SIZE:
			continue
		
		var adjacent_card = grid.grid[check_x][check_y]
		
		# Si hay un monstruo adyacente
		if adjacent_card and adjacent_card is CartaMonstruo:
			# Verificar si ese adyacente tiene Escurridizo
			var adjacent_has_escurridizo = false
			
			for rasgo in adjacent_card.rasgos:
				if rasgo is Escurridizo:
					adjacent_has_escurridizo = true
					break
			
			# Si NO tiene Escurridizo, este monstruo está protegido
			if not adjacent_has_escurridizo:
				has_adjacent_without_escurridizo = true
				break
	
	# Si tiene monstruos adyacentes sin Escurridizo, NO puede ser atacado
	if has_adjacent_without_escurridizo:
		print("Escurridizo: %s está protegido por monstruos adyacentes" % monster.name)
		return false
	
	return true
