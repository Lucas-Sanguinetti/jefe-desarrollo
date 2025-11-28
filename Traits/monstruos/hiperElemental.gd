extends TraitBase
class_name HiperElemental


@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var reduced_damage = damage
	if attacker.element == defender.element:
		reduced_damage = 0

	return reduced_damage
