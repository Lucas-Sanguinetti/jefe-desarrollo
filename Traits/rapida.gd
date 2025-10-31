extends TraitBase
class_name Rapida

@export var multiplicador:int = 2

func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var player_grid = attacker.parent_grid
	# Solo funciona si el arma está equipada en PlayerWeaponGrid
	#if not player_grid or not player_grid is PlayerWeaponGrid:
		#return damage
	# Verificar si es el primer ataque del turno
	if player_grid.is_first_attack_of_turn():
		var boosted_damage = int(damage * multiplicador)
		print("%s (Rápida): ¡PRIMER ATAQUE! Daño %d → %d (x%d)" % [attacker.name, damage, boosted_damage, multiplicador])
		return boosted_damage
	# Debug: Ya se uso el primer ataque
	print("%s (Rápida): No es el primer ataque (daño normal: %d)" % [attacker.name, damage])
	return damage
