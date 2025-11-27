extends Resource
class_name WeaponAbilityData
# TIPOS DE OBJETIVO
enum TargetType {
	NONE,      # Auto-cast (self-buff)
	WEAPON     # Selecciona otra arma equipada
}

# PROPIEDADES BÁSICAS
@export var ability_name: String = ""
@export var ability_description: String = ""

@export_group("Targeting")
@export var target_type: TargetType = TargetType.NONE

@export_group("Effect")
@export var ability_id: String = ""  # ID único para lógica personalizada

# Valores genéricos
@export var value_1: int = 0
@export var value_2: int = 0
@export var value_3: int = 0
@export var custom_params: Dictionary = {}

#VALIDACION
func is_valid_target(target) -> bool:
	match target_type:
		TargetType.WEAPON:
			return target is CartaArma
	
	return false

# HELPERS
func get_param(key: String, default = null):
	return custom_params.get(key, default)

func has_param(key: String) -> bool:
	return key in custom_params

func get_target_type_string() -> String:
	match target_type:
		TargetType.NONE: return "Auto"
		TargetType.WEAPON: return "Arma"
	return "Desconocido"	
