extends TraitBase
class_name Antivida

@warning_ignore("unused_parameter")
func on_monster_spawned(monster: CartaMonstruo):
	TurnManager.block_healing(true)


@warning_ignore("unused_parameter")
func on_monster_death(monster: CartaMonstruo):
	TurnManager.block_healing(false)
