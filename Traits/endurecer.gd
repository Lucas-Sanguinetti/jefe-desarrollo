extends TraitBase
class_name Endurecer

@export var resistencia:int = 1


@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var reduced_damage = max(damage - resistencia,0)
	print("%s (Defense Trait): Daño reducido de %d a %d" % [defender.name, damage, reduced_damage])
	return reduced_damage
