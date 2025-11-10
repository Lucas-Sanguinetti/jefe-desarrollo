extends Resource
class_name TraitBase

@export var trait_name: String 
@export var trait_description: String 

#aplica efectos cuando las armas atacan
@warning_ignore("unused_parameter")
func do_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	#push_warning("%s no implementó do_damage()" % [get_script().resource_path]) #Debug
	return damage

#damage efectos cuando los monstruos reciben daño
@warning_ignore("unused_parameter")
func take_damage(attacker: Carta, defender: Carta, damage: int) -> int:
	#push_warning("%s no implementó take_damage()" % [get_script().resource_path]) #Debug
	return damage

#aplica efectos cuando el jugador recibe daño
@warning_ignore("unused_parameter")
func on_player_damage(damage: int, monster: Carta) -> int:
	#push_warning("%s no implementó on_player_damage()" % [get_script().resource_path]) #Debug
	return damage

#efectos o reseteos de variables de traits al finalizar el turno
@warning_ignore("unused_parameter")
func on_turn_reset(card: Carta) -> void:
	#push_warning("%s no implementó on_turn_reset()" % [get_script().resource_path]) #Debug
	pass
