extends TraitBase
class_name Venganza

var multiplicador:int = 2
var golpeado:bool = false

@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	golpeado = true
	
	return damage
	
func on_player_damage(damage: int, monster: Carta) -> int:
	push_error(golpeado,monster.data.name)
	var boost_Damage:int = damage
	if golpeado:
		boost_Damage = int(damage * multiplicador)
	print("%s (Venganza Trait): Daño aumentado de %d a %d" % [monster.name, damage, boost_Damage])
	return boost_Damage

@warning_ignore("unused_parameter")
func on_turn_reset(card: Carta) -> void:
	golpeado = false
	push_error(golpeado,card.data.name)
