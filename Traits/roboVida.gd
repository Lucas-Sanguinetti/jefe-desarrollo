extends TraitBase
class_name RobaVida


@warning_ignore("unused_parameter")
func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	if LifeManager.get_life() <= damage:
		return damage
	LifeManager.gainLife(damage)
	print("%s (Lifesteal Trait): Se recuperaron %d de vida" % [attacker.name, damage])
	return damage
