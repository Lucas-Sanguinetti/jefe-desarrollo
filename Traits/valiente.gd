extends TraitBase
class_name Valiente

# Verificar si este monstruo está protegido por algún Valiente adyacente
func is_protected_by_valiant(defender: Carta) -> bool:
	# Si el defensor tiene Valiente, no está protegido
	if defender.data is MonsterCardData:
		for rasgo in defender.data.traits:
			if rasgo is Valiente:
				return false
	
	# Buscar Valientes adyacentes
	var adjacent_valiants = get_adjacent_valiant_monsters(defender)
	return not adjacent_valiants.is_empty()

# Obtener monstruos Valientes adyacentes
func get_adjacent_valiant_monsters(card: Carta) -> Array:
	var valiants = []
	var grid = card.parent_grid
	
	if not grid or not grid is MonsterGrid:
		return valiants
	
	var pos = card.grid_pos
	var x = int(pos.x)
	var y = int(pos.y)
	
	# Direcciones ortogonales: arriba, abajo, izquierda, derecha
	var directions = [
		Vector2(0, -1),  # Arriba
		Vector2(0, 1),   # Abajo
		Vector2(-1, 0),  # Izquierda
		Vector2(1, 0)    # Derecha
	]
	
	for dir in directions:
		var check_x = x + int(dir.x)
		var check_y = y + int(dir.y)
		
		# Verificar límites del grid
		if check_x < 0 or check_x >= grid.GRID_SIZE or check_y < 0 or check_y >= grid.GRID_SIZE:
			continue
		
		var adjacent_card = grid.grid[check_x][check_y]
		if adjacent_card and adjacent_card.data is MonsterCardData:
			# Verificar si el monstruo adyacente tiene Valiente
			for rasgo in adjacent_card.data.traits:
				if rasgo is Valiente:
					valiants.append(adjacent_card)
					break
	
	return valiants

# Obtener posiciones protegidas por este monstruo Valiente
func get_protected_positions(valiant_card: Carta) -> Array:
	var protected_positions = []
	var grid = valiant_card.parent_grid
	
	if not grid or not grid is MonsterGrid:
		return protected_positions
	
	var pos = valiant_card.grid_pos
	var x = int(pos.x)
	var y = int(pos.y)
	
	# Direcciones ortogonales
	var directions = [
		Vector2(0, -1),  # Arriba
		Vector2(0, 1),   # Abajo
		Vector2(-1, 0),  # Izquierda
		Vector2(1, 0)    # Derecha
	]
	
	for dir in directions:
		var check_x = x + int(dir.x)
		var check_y = y + int(dir.y)
		
		# Verificar límites del grid
		if check_x < 0 or check_x >= grid.GRID_SIZE or check_y < 0 or check_y >= grid.GRID_SIZE:
			continue
		
		var adjacent_card = grid.grid[check_x][check_y]
		
		# Solo protege si hay un monstruo y NO tiene Valiente
		if adjacent_card and adjacent_card.data is MonsterCardData:
			var has_valiant = false
			for rasgo in adjacent_card.data.traits:
				if rasgo is Valiente:
					has_valiant = true
					break
			
			if not has_valiant:
				protected_positions.append(Vector2(check_x, check_y))
	
	return protected_positions
