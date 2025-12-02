# acorazado.gd - Gana Endurecer +5 cada vez que es golpeado
extends TraitBase
class_name Acorazado

@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	# Obtener resistencia acumulada este turno
	var current_resistance = defender.get_trait_state("acorazado_resistance", 0)
	
	# Reducir daño según resistencia acumulada
	var reduced_damage = max(0, damage - current_resistance)
	
	#Debug
	print("Acorazado: Resistencia +5 (total: %d) - Daño %d → %d" % [
		current_resistance,
		damage,
		reduced_damage
	])
	
	return reduced_damage

func buff_resistance(monster:Carta):
	var current_resistance = monster.get_trait_state("acorazado_resistance", 0)
	current_resistance += 5
	monster.set_trait_state("acorazado_resistance", current_resistance)
	

func on_turn_reset(card: Carta):
	var old_resistance = card.get_trait_state("acorazado_resistance", 0)
	
	if old_resistance > 0:
		card.clear_trait_state("acorazado_resistance")
		print("Acorazado: Resistencia reseteada (era %d)" % old_resistance)
