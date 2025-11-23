extends CardData
class_name MonsterCardData

@export var hp: int
@export var attack: int
@export var traits: Array[TraitBase] = []
@export var nivel:int = 1
@export var element:Texture2D = preload("uid://cfghlodo6mm6e")
@export var backsprite:Texture2D = preload("uid://bm7c1ddxe8pm6")
@export var death:AudioStream = preload("uid://dns6okc5us4st")
