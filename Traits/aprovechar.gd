extends TraitBase
class_name Aprovechar

@export var multiplicador:int = 2

func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var boost_Damage:int = damage
	if defender.hp_actual != defender.max_hp:
		boost_Damage = int(damage * multiplicador)
		print("%s (Aprovechar Trait): Daño aumentado de %d a %d" % [attacker.name, damage, boost_Damage])
	return boost_Damage

func on_player_damage(damage: int, monster: Carta) -> int:
	var boost_Damage:int = damage
	if LifeManager.get_life() < LifeManager.get_maxLife():
		boost_Damage = int(damage * multiplicador)
		print("%s (Aprovechar Trait): Daño aumentado de %d a %d" % [monster.name, damage, boost_Damage])
	return boost_Damage
