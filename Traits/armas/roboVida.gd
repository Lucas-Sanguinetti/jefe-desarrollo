extends TraitBase
class_name RobaVida


@warning_ignore("unused_parameter")
func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	return damage

func get_lifesteal_amount(attacker: Carta,weapon_damage: int, defender: Carta) -> int:
	var actual_damage = weapon_damage
	for rasgo in defender.data.traits:
		actual_damage = rasgo.take_damage(attacker, defender, actual_damage)
	
	print("%s (Lifesteal Trait): Vida a recuperar: %d (ataque: %d - defensas: %d)" % [defender.name, actual_damage, weapon_damage, weapon_damage - actual_damage])
	return actual_damage
