extends Carta
class_name CartaMonstruo

# Referencias específicas de monstruos
var vida_label: Label
var ataque_label: Label
var traits_label: Label
var niveles_sprite: Sprite2D 
var element_sprite: TextureRect
var backsprite_sprite: TextureRect

var backsprite: Texture2D
var element:Texture2D
var hp_actual:int
var ataque:int
var max_hp:int
var nivel:int 

var golpeado:bool = false

@onready var death: AudioStreamPlayer = $Death


# IMPLEMENTACIÓN DE MÉTODOS VIRTUALES
func _initialize_references() -> void:
	super._initialize_references()
	vida_label = get_node_or_null("Vida")
	ataque_label = get_node_or_null("Ataque")
	traits_label = get_node_or_null("MonsterTraits")
	niveles_sprite = get_node_or_null("Niveles")
	element_sprite = get_node_or_null("Element")
	backsprite_sprite = get_node_or_null("BackSprite")
	
	# Validación
	if not vida_label:
		push_error("CartaMonstruo: Falta nodo 'Vida'")
	if not ataque_label:
		push_error("CartaMonstruo: Falta nodo 'Ataque'")
	if not traits_label:
		push_error("CartaMonstruo: Falta nodo 'MonsterTraits'")
	if not niveles_sprite:
		push_error("CartaArma: Falta nodo 'Niveles'")

func _setup_specific_ui() -> void:
	var monster_data = data as MonsterCardData
	if not monster_data:
		push_error("CartaMonstruo requiere MonsterCardData")
		return
	
	hp_actual = monster_data.hp
	ataque = monster_data.attack
	max_hp = monster_data.hp
	nivel = monster_data.nivel
	element = monster_data.element
	backsprite = monster_data.backsprite
	if traits_label:
		traits_label.text = _get_traits_text(monster_data)
	if niveles_sprite:
		niveles_sprite.set_nivel(nivel)
	if ataque_label:
		ataque_label.text = str(ataque)
	_apply_data_to_ui()

func _apply_data_to_ui() -> void:
	if vida_label:
		vida_label.text = str(hp_actual)
	if element_sprite:
		element_sprite.texture = element
	if backsprite_sprite:
		backsprite_sprite.texture = backsprite
	

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
		die(nivel)
		death.play()
		

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
