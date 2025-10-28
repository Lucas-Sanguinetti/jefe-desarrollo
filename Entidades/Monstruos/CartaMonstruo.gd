extends Carta
class_name CartaMonstruo

# Referencias específicas de monstruos
@onready var vida_label: Label = $Vida
@onready var ataque_label: Label = $Ataque
@onready var traits_label: Label = $MonsterTraits
var hp_actual:int
var ataque:int
var max_hp:int
var golpeado:bool = false


# IMPLEMENTACIÓN DE MÉTODOS VIRTUALES
func _initialize_references() -> void:
	super._initialize_references()  # Llamar al padre primero
	# Las referencias @onready ya están disponibles

func _setup_specific_ui() -> void:
	var monster_data = data as MonsterCardData
	if not monster_data:
		push_error("CartaMonstruo requiere MonsterCardData")
		return
	
	hp_actual = monster_data.hp
	ataque = monster_data.attack
	max_hp = monster_data.hp
	traits_label.text = _get_traits_text(monster_data)

func _apply_data_to_ui() -> void:
	ataque_label.text = str(ataque)
	vida_label.text = str(hp_actual)
	

# CAPACIDADES DE COMBATE
func can_be_targeted() -> bool:
	return true 

# LÓGICA ESPECÍFICA DE MONSTRUOS
func take_damage(damage: int, attacker: Carta = null) -> void:
	var monster_data = data as MonsterCardData
	
	# Aplicar reducción de traits
	for traits in monster_data.traits:
		damage = traits.take_damage(attacker, self, damage)
	
	hp_actual -= damage
	_apply_data_to_ui()  # Actualizar vida en pantalla
	create_damage_effect()
	
	if hp_actual <= 0:
		die()

func get_monster_hps() -> Array:
	var vidas: Array = []
	vidas.append(hp_actual)
	vidas.append(max_hp)
	return vidas


# UTILIDADES PRIVADAS
func _get_traits_text(monster_data: MonsterCardData) -> String:
	var texto: String = ""
	for traits in monster_data.traits:
		texto += "* %s\n" % [traits.trait_name]
	return texto
