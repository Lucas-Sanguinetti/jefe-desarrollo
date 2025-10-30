extends Carta
class_name CartaMonstruo

# Referencias específicas de monstruos
var vida_label: Label
var ataque_label: Label
var traits_label: Label
var niveles_sprite: Sprite2D 

var hp_actual:int
var ataque:int
var max_hp:int
var nivel:int 
var rasgos:Array

var golpeado:bool = false


# IMPLEMENTACIÓN DE MÉTODOS VIRTUALES
func _initialize_references() -> void:
	super._initialize_references()
	vida_label = get_node_or_null("Vida")
	ataque_label = get_node_or_null("Ataque")
	traits_label = get_node_or_null("MonsterTraits")
	niveles_sprite = get_node_or_null("Niveles")
	
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
	rasgos = monster_data.traits
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
	

# CAPACIDADES DE COMBATE
func can_be_targeted() -> bool:
	for rasgo in rasgos:
		if rasgo is Valiente:
			return true
	
	var grid = parent_grid
	if grid and grid is MonsterGrid:
		var pos = grid_pos
		var x = int(pos.x)
		var y = int(pos.y)
		
		var directions = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
		
		for dir in directions:
			var check_x = x + int(dir.x)
			var check_y = y + int(dir.y)
			
			if check_x < 0 or check_x >= grid.GRID_SIZE or check_y < 0 or check_y >= grid.GRID_SIZE:
				continue
			
			var adjacent_card = grid.grid[check_x][check_y]
			if adjacent_card and adjacent_card.data is MonsterCardData:
				# Verificar si el adyacente tiene Valiente
				for adj_trait in adjacent_card.data.traits:
					if adj_trait is Valiente:
						print("DEBUG: %s está protegido por Valiente en [%d,%d]" % [name, check_x, check_y])
						return false
	return true 

# LÓGICA ESPECÍFICA DE MONSTRUOS
func take_damage(damage: int, attacker: Carta = null) -> void:
	
	# Aplicar reducción de traits
	for rasgo in rasgos:
		damage = rasgo.take_damage(attacker, self, damage)
	
	hp_actual -= damage
	_apply_data_to_ui()  # Actualizar vida en pantalla
	if parent_grid and parent_grid.has_node("MonsterGridVisuals"):
		var visuals = parent_grid.get_node("MonsterGridVisuals")
		visuals.show_damage_effect(self)
	else:
		create_damage_effect()
	
	if hp_actual <= 0:
		die(nivel)

@warning_ignore("shadowed_variable")
func die(nivel:int) -> void:
	print("CartaMonstruo: %s ha muerto" % [name])
	MoneyManager.ganarMonedas(nivel)
	# Activar Renacer ANTES de la animación de muerte
	for rasgo in rasgos:
		if rasgo is Renacer:
			rasgo.on_monster_death(self)
	
	emit_signal("card_died")
	
	if parent_grid and parent_grid.has_node("MonsterGridVisuals"):
		var visuals = parent_grid.get_node("MonsterGridVisuals")
		var tween = visuals.animate_death(self)
		tween.tween_callback(queue_free)
	else:
		_play_death_animation()  # Fallback del padre
	
	if parent_grid and parent_grid.has_method("update_on_card_death"):
		parent_grid.update_on_card_death(self)

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
