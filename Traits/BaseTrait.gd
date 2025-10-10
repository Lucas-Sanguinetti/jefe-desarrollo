extends Resource
class_name TraitBase

@export var trait_name: String 
@export var trait_description: String 

func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	push_error("%s no implementó do_damage()" % [get_script().resource_path])
	return damage

func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	push_error("%s no implementó take_damage()" % [get_script().resource_path])
	return damage

func on_player_damage(damage: int, monster: Carta) -> int:
	push_error("%s no implementó on_player_damage()" % [get_script().resource_path])
	return damage

func on_turn_reset(card: Carta) -> void:
	push_error("%s no implementó on_turn_reset()" % [get_script().resource_path])
	pass
