extends CardData
class_name WeaponCardData

enum ElementType {
	DARK,
	EARTH,
	ELECTRIC,
	FIRE,
	ICE,
	NATURE,
	POISON,
	TECH,
	WATER,
	WIND
}

@export var attack: int
@export var traits: Array[TraitBase] = []
@export var nivel:int = 1
@export var element_type: ElementType = ElementType.DARK
@export var element:Texture2D = preload("uid://cfghlodo6mm6e")
@export var backsprite:Texture2D =preload("uid://dgmb8r1w73p1r")
@export var drawSword:AudioStream = preload("uid://saalgqj02ulo")
@export var swordHit:AudioStream = preload("uid://box1cwy2ha3ex")

# SISTEMA DE HABILIDADES (NUEVO)
@export var ability: WeaponAbilityData = null  # null = sin habilidad

# HELPERS
func has_ability() -> bool:
	return ability != null

func get_ability_description() -> String:
	if not ability:
		return "Sin habilidad especial"
	
	var text = "%s\n" % ability.ability_name
	text += "%s\n" % ability.ability_description
	text += "Objetivo: %s" % ability.get_target_type_string()
	return text
