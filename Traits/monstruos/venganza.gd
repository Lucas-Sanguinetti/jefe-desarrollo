extends TraitBase
class_name Venganza

@export var multiplicador: int = 2

@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	# Marcar en el estado de la carta que fue golpeado
	defender.set_trait_state("venganza_golpeado", true)
	return damage


func on_player_damage(damage: int, monster: Carta) -> int:
	var fue_golpeado = monster.get_trait_state("venganza_golpeado", false)
	
	if fue_golpeado:
		var boost_damage = int(damage * multiplicador)
		print("%s (Venganza Trait): Daño aumentado de %d a %d" % [monster.name, damage, boost_damage])
		return boost_damage
	
	return damage


func on_turn_reset(card: Carta) -> void:
	card.set_trait_state("venganza_golpeado", false)
