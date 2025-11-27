extends TraitBase
class_name Rapida

@export var multiplicador:int = 2

@warning_ignore("unused_parameter")
func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var player_grid = attacker.parent_grid
	# Verificar si es el primer ataque del turno
	if player_grid.is_first_attack_of_turn():
		var boosted_damage = int(damage * multiplicador)
		print("%s (Rápida): ¡PRIMER ATAQUE! Daño %d → %d (x%d)" % [attacker.name, damage, boosted_damage, multiplicador])
		return boosted_damage

	return damage
