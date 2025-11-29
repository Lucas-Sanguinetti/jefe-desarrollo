extends CardData
class_name MonsterCardData

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

@export var hp: int
@export var attack: int
@export var traits: Array[TraitBase] = []
@export var nivel:int = 1
@export var element_type: ElementType = ElementType.DARK
@export var element:Texture2D = preload("uid://cfghlodo6mm6e")
@export var backsprite:Texture2D = preload("uid://c5dbe2itbl2gn")
@export var death:AudioStream = preload("uid://dns6okc5us4st")
@export var boss:bool = false
