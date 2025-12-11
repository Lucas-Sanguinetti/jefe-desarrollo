extends TraitBase
class_name AprovecharArma


func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var boost_Damage:int = damage
	if defender.hp_actual != defender.max_hp:
		boost_Damage = int(damage * 2)
		print("%s (Aprovechar Trait): Daño aumentado de %d a %d" % [attacker.name, damage, boost_Damage])
	return boost_Damage
