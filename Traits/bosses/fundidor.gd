extends TraitBase
class_name Fundidor

@warning_ignore("unused_parameter")
func on_monster_spawned(monster: CartaMonstruo):
	TurnManager.block_weapon_purchases(true)


@warning_ignore("unused_parameter")
func on_monster_death(monster: CartaMonstruo):
	TurnManager.block_weapon_purchases(false)
