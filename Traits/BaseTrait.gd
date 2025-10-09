extends Resource
class_name TraitBase

@export var trait_name: String 
@export var trait_description: String 

func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	return damage

func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	return damage

func on_player_damage(damage: int, monster: Carta) -> int:
	return damage

func on_turn_reset(card: Carta) -> void:
	pass
