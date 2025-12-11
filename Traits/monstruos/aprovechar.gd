extends TraitBase
class_name Aprovechar

func on_player_damage(damage: int, monster: Carta) -> int:
	var boost_Damage:int = damage
	if LifeManager.get_life() < LifeManager.get_maxLife():
		boost_Damage = int(damage * 2)
		print("%s (Aprovechar Trait): Daño aumentado de %d a %d" % [monster.name, damage, boost_Damage])
	return boost_Damage
