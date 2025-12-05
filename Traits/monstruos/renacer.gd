extends TraitBase
class_name Renacer

@export var vida_extra: int = 0

func on_monster_death(dead_monster: Carta):
	print("%s (Renacer): Activando con %d de vida extra" % [dead_monster.name, vida_extra])
	
	var grid = dead_monster.parent_grid
	if not grid or not grid is MonsterGrid:
		push_error("Renacer: No hay MonsterGrid válido")
		return
	
	# Guardar la posición del monstruo muerto
	var spawn_position = dead_monster.grid_pos
	
	# Verificar si el mazo tiene cartas
	if not MonsterDeck or MonsterDeck.size() <= 0:
		print("Renacer: Mazo vacío, fallo silencioso")
		return
	
	# Robar monstruo del mazo
	var new_monster_data = MonsterDeck.draw1()
	if not new_monster_data:
		push_error("Renacer: No se pudo robar carta del mazo")
		return
	
	# IMPORTANTE: Duplicar el resource para no modificar el original
	var modified_data = new_monster_data.duplicate(true)
	modified_data.hp += vida_extra
	
	# Usar call_deferred para invocar después de que se limpie la celda
	grid.call_deferred("_spawn_from_renacer", spawn_position, modified_data)
