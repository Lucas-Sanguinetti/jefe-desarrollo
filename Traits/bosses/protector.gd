extends TraitBase
class_name Protector

func on_monster_spawned(monster: CartaMonstruo):
	TurnManager.set_forced_target(monster)
	print("Protector: Solo %s puede ser atacado" % monster.name)

@warning_ignore("unused_parameter")
func on_monster_death(monster: CartaMonstruo):
	TurnManager.clear_forced_target()
	print("Protector: Ataques libres de nuevo")
