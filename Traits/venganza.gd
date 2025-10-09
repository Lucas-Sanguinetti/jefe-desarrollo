extends TraitBase
class_name Venganza

@export var multiplicador:int = 2
var golpeado:bool = false

func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	var boost_Damage:int = damage
	if golpeado:
		boost_Damage = int(damage * multiplicador)
	print("%s (Power Trait): Daño aumentado de %d a %d" % [attacker.name, damage, boost_Damage])
	return boost_Damage

func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	golpeado = true
	return damage

func on_turn_reset(card: Carta) -> void:
	golpeado = false
