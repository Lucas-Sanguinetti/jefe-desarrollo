extends TraitBase
class_name Fragil

@export var fragilidad:int = 1

@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var incresead_damage = damage + fragilidad
	print("%s (Fragil Trait): Daño aumentado de %d a %d" % [defender.name, damage, incresead_damage])
	return incresead_damage
