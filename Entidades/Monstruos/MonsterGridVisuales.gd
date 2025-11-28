extends Node
class_name MonsterGridVisuals

var grid: MonsterGrid
var protection_overlays: Array = []
var escurridizo_overlays: Array = []

func _ready():
	grid = get_parent() as MonsterGrid
	if not grid:
		push_error("MonsterGridVisuals debe ser hijo de MonsterGrid")

# ANIMACIONES DE PROTECCIÓN (VALIENTE)
func update_valiente_overlays():
	clear_protection_overlays()
	
	for x in range(grid.GRID_SIZE):
		for y in range(grid.GRID_SIZE):
			var card = grid.grid[x][y]
			if card and card.data is MonsterCardData:
				for rasgo in card.data.traits:
					if rasgo is Valiente:
						create_protection_overlays_for_valiente(card, rasgo)
						break

func create_protection_overlays_for_valiente(valiant_card: Carta, valiant_trait: Valiente):
	var protected_positions = valiant_trait.get_protected_positions(valiant_card)
	
	for pos in protected_positions:
		var overlay = Panel.new()
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Estilo: borde dorado brillante
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1, 0.84, 0, 0.2)  # Dorado semitransparente
		style.border_color = Color(1, 0.84, 0, 1)  # Dorado sólido
		style.set_border_width_all(3)
		overlay.add_theme_stylebox_override("panel", style)
		
		# Posicionar en la celda
		var world_pos = grid.grid_to_world(int(pos.x), int(pos.y))
		overlay.position = world_pos - Vector2(42, 62)
		overlay.size = Vector2(84, 124)
		
		#Agregar al grid
		grid.add_child(overlay)
		#Guardar referencia
		protection_overlays.append(overlay)
		
		# Animación de aparición
		animate_overlay_appear(overlay)

func clear_protection_overlays():
	for overlay in protection_overlays:
		if is_instance_valid(overlay):
			overlay.queue_free()
	protection_overlays.clear()

# ANIMACIONES DE ESCONDERSE (ESCURRIDIZO)
func update_escurridizo_overlays():
	clear_escurridizo_overlays()
	
	for x in range(grid.GRID_SIZE):
		for y in range(grid.GRID_SIZE):
			var card = grid.grid[x][y]
			if card and card.data is MonsterCardData:
				for rasgo in card.data.traits:
					if rasgo is Escurridizo:
						create_shadow_overlays_for_escurridizos(card, rasgo)
						break

func create_shadow_overlays_for_escurridizos(escurridizo_card: Carta, escurridizo_trait: Escurridizo):
	if not escurridizo_trait.can_be_targeted_override(escurridizo_card):
		var overlay = Panel.new()
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Estilo: borde dorado brillante
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0.3, 0.4)  # Azul oscuro semitransparente
		style.border_color = Color(0.0, 0.5, 1.0, 1.0)  # Azul brillante
		style.set_border_width_all(3)
		overlay.add_theme_stylebox_override("panel", style)
		
		# Posicionar en la celda
		var grid_pos = escurridizo_card.grid_pos
		var world_pos = grid.grid_to_world(int(grid_pos.x), int(grid_pos.y))
		overlay.position = world_pos - Vector2(42, 62)
		overlay.size = Vector2(84, 124)
		
		#Agregar al grid
		grid.add_child(overlay)
		#Guardar referencia
		escurridizo_overlays.append(overlay)
		
		# Animación de aparición
		animate_overlay_appear(overlay)
		print("MonsterGridVisuals: %s está protegido por Escurridizo" % escurridizo_card.name)

func clear_escurridizo_overlays():
	for overlay in escurridizo_overlays:
		if is_instance_valid(overlay):
			overlay.queue_free()
	escurridizo_overlays.clear()
	
func animate_overlay_appear(overlay: Panel):
	overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.3)

# ANIMACIONES DE SPAWN (RENACER)
func show_spawn_effect(position: Vector2, spawned_card: Carta):
	# Efecto de partículas/círculo en la posición
	create_spawn_circle(position)
	
	# Animación de aparición de la carta
	if spawned_card:
		animate_card_spawn(spawned_card)

func create_spawn_circle(grid_position: Vector2):
	var world_pos = grid.grid_to_world(int(grid_position.x), int(grid_position.y))
	
	# Crear círculo visual temporal
	var circle = ColorRect.new()
	circle.color = Color(0.5, 1, 0.5, 0.6)  # Verde brillante
	circle.size = Vector2(84, 124)
	circle.position = world_pos - Vector2(42, 62)
	grid.add_child(circle)
	
	# Animación de expansión y desvanecimiento
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(circle, "scale", Vector2(1.3, 1.3), 0.5)
	tween.tween_property(circle, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(circle.queue_free)

func animate_card_spawn(card: Carta):
	# La carta aparece desde escala pequeña
	card.scale = Vector2(0.1, 0.1)
	card.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "modulate:a", 1.0, 0.3)
	
	# Efecto de brillo
	tween.chain().tween_callback(func(): flash_card(card))

func flash_card(card: Carta):
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(card, "modulate", Color.WHITE, 0.1)


# ANIMACIONES DE MUERTE
func animate_death(card: Carta):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "rotation", PI, 0.5)
	tween.tween_property(card, "scale", Vector2.ZERO, 0.5)
	tween.tween_property(card, "modulate:a", 0.0, 0.5)
	return tween  # Retornar para encadenar callbacks


# EFECTOS DE COMBATE
func show_damage_effect(card: Carta):
	var tween = create_tween()
	tween.tween_property(card, "modulate", Color.RED, 0.1)
	tween.tween_property(card, "modulate", Color.WHITE, 0.1)

func show_attack_path(attacker: Carta, target: Carta):
	# Línea visual del ataque
	var line = Line2D.new()
	line.width = 3
	line.default_color = Color.YELLOW
	line.add_point(attacker.global_position)
	line.add_point(target.global_position)	
	grid.add_child(line)
	
	# Desvanecer y eliminar
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.3)
	tween.tween_callback(line.queue_free)
