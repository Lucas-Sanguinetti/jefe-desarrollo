extends TraitBase
class_name Solitario

func on_player_damage(damage: int, monster: Carta) -> int:
	if not monster or not monster is CartaMonstruo:
		return damage
	
	# Verificar si está solo (sin monstruos adyacentes)
	if _is_alone(monster):
		var doubled_damage = damage * 2
		print("Solitario: %s está solo - Daño duplicado (%d → %d)" % [monster.name, damage, doubled_damage])
		return doubled_damage
	else:
		print("Solitario: %s tiene compañía - Daño normal" % monster.name)
		return damage


func _is_alone(monster: CartaMonstruo) -> bool:
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
	
	for dir in directions:
		var check_x = x + int(dir.x)
		var check_y = y + int(dir.y)
		
		# Verificar límites del grid
		if check_x < 0 or check_x >= grid.GRID_SIZE or check_y < 0 or check_y >= grid.GRID_SIZE:
			continue
		
		var adjacent_card = grid.grid[check_x][check_y]
		
		# Si hay un monstruo adyacente
		if adjacent_card and adjacent_card is CartaMonstruo:
			return false
			
	return true
