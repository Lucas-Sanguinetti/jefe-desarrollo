extends CardData
class_name SpellCardData

enum TargetType {
	NONE,           # Auto-cast (heal jugador, buff global)
	WEAPON,         # Selecciona arma equipada
	MONSTER,        # Selecciona monstruo enemigo
	SPELL_IN_HAND,  # Selecciona otro hechizo en mano
	SUMMON          # Invoca monstruo en grid (no requiere selección)
}

enum EffectCategory {
	DAMAGE,         # Afecta HP de enemigos
	HEALING,        # Afecta HP del jugador
	BUFF,           # Mejora armas/stats
	UTILITY,        # Duplicar, eliminar, recargar
	SUMMON,         # Invocar criaturas
	ECONOMY         # Monedas
}

@export var descripcion: String = ""
@export var backsprite: Texture2D = preload("uid://54m7t5misdgh")
@export var death:AudioStream = preload("uid://d17faolx3o0y1")

@export_group("Targeting")
@export var target_type: TargetType = TargetType.NONE

@export_group("Effect System")
@export var effect_category: EffectCategory = EffectCategory.DAMAGE
@export var effect_id: String = ""  # ID único para lógica personalizada (opcional)

@export_group("Effect Values")
@export var effect_value: int = 0        # Valor principal
@export var secondary_value: int = 0     # Valor secundario
@export var tertiary_value: int = 0      # Valor terciario
@export var custom_params: Dictionary = {}  # Parámetros adicionales

@export_group("Restrictions")
@export var one_time_use: bool = false  # Si true, no vuelve al mazo
@export var cost_money: int = 0

func is_valid_target(target) -> bool:
	match target_type:
		TargetType.NONE, TargetType.SUMMON:
			return true
		
		TargetType.WEAPON:
			if not target is CartaArma:
				return false
			return true
		
		TargetType.MONSTER:
			if not target is CartaMonstruo:
				return false
			if not target.can_be_targeted():
				return false
			return true
		
		TargetType.SPELL_IN_HAND:
			return target is CartaHechizo and target.data != self
	
	return false

# ============================================
# HELPERS (solo lectura)
# ============================================
func get_param(key: String, default = null):
	return custom_params.get(key, default)

func has_param(key: String) -> bool:
	return key in custom_params

# ============================================
# INFO PARA UI
# ============================================
func get_full_description() -> String:
	var text = descripcion
	
	if one_time_use:
		text += "\n[Uso único - No vuelve al mazo]"
	
	if cost_money > 0:
		text += "\n[Coste: %d monedas]" % cost_money
	
	return text

func get_target_type_string() -> String:
	match target_type:
		TargetType.NONE: return "Auto"
		TargetType.WEAPON: return "Arma"
		TargetType.MONSTER: return "Monstruo"
		TargetType.SPELL_IN_HAND: return "Hechizo"
		TargetType.SUMMON: return "Invocación"
	return "Desconocido"

func get_category_string() -> String:
	match effect_category:
		EffectCategory.DAMAGE: return "Daño"
		EffectCategory.HEALING: return "Curación"
		EffectCategory.BUFF: return "Mejora"
		EffectCategory.UTILITY: return "Utilidad"
		EffectCategory.SUMMON: return "Invocación"
		EffectCategory.ECONOMY: return "Economía"
	return "Desconocido"
