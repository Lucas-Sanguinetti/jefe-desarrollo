extends TraitBase
class_name Cazarrecompensas

@export var multiplicador:int = 2

@warning_ignore("unused_parameter")
func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var actual_damage = damage
	for rasgo in defender.data.traits:
		actual_damage = rasgo.take_damage(null, defender, actual_damage)
		
	if defender.hp_actual < actual_damage:
		MoneyManager.ganarMonedas(1)
	return actual_damage
