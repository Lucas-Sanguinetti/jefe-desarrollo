extends TraitBase
class_name CriticoElemental


func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var boost_Damage:int = damage
	if attacker.element == defender.element:
		boost_Damage = int(damage * 2)
		print("%s (CriticoElemental Trait): Daño critico de %d a %d" % [attacker.name, damage, boost_Damage])
	return boost_Damage
