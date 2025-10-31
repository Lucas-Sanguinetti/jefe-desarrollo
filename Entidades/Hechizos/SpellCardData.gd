extends CardData
class_name SpellCardData

enum TargetType {
	SELF,      # Se aplica al jugador
	ENEMY,     # Requiere seleccionar enemigo
	ALL_ENEMIES,
	RANDOM_ENEMY
}

enum EffectType {
	DAMAGE,
	HEAL,
	BUFF
}

@export var descripcion:String = ""
@export var backsprite:Texture2D = preload("uid://e0yx28713rag")

@export var target_type: TargetType = TargetType.SELF
@export var effect_type: EffectType = EffectType.DAMAGE

@export var effect_value: int = 0 
@export var duration: int = 0 #Para los buffs

# Identificador para el sistema de efectos
@export var effect_id: String = ""
