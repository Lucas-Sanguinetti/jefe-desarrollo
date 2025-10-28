extends Node2D
class_name CartaComplicada

@export var data: CardData
@export var can_attack: bool = true 

var grid_pos: Vector2
var parent_grid: Node2D = null  # Referencia al grid padre
@onready var sprite: TextureRect = $Sprite
var resaltadoDeAtaque: Panel
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat  
var style_cannot_attack: StyleBoxFlat
@onready var area: Area2D = $Area

# Variables para detectar doble click
var click_timer: float = 0.0
var click_threshold: float = 0.3  # 300ms para detectar doble click
var click_count: int = 0

signal mouseSobreCarta(carta: Carta)
signal mouseFueraCarta
signal card_selected_for_attack
signal card_targeted_for_attack
signal card_died
signal card_double_clicked(carta: Carta)

enum CardState {
	NORMAL,
	SELECTED_FOR_ATTACK,
	CANNOT_ATTACK
}

var current_state: CardState = CardState.NORMAL

func _ready() -> void:
	sprite.texture = data.sprite
	
	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color.TRANSPARENT
	
	style_selected = StyleBoxFlat.new() 
	style_selected.bg_color = Color(0, 1, 0, 0.4) 
	
	style_cannot_attack = StyleBoxFlat.new()
	style_cannot_attack.bg_color = Color(0.36, 0.35, 0.337, 0.0)
	
	resaltadoDeAtaque = Panel.new()
	resaltadoDeAtaque.name = "resaltadoDeAtaque"
	resaltadoDeAtaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resaltadoDeAtaque.visible = false
	resaltadoDeAtaque.position = Vector2(-42, -62)
	resaltadoDeAtaque.size = Vector2(84, 124)
	add_child(resaltadoDeAtaque)
	
	setup_card_ui()
	
	# Guardar referencia al grid padre
	parent_grid = get_parent()
	
	# Conectar señales con CardManager
	call_deferred("connect_to_manager")
	
	#se conecta para el info display
	


func connect_to_manager():
	if not is_inside_tree():
		await tree_entered

	var manager = get_tree().get_first_node_in_group("CardManager")
	if manager:
		if manager.has_method("connect_combat_signals"):
			manager.connect_combat_signals(self)
		if manager.has_method("connect_card_signals"):
			manager.connect_card_signals(self)

func setup(datos: CardData):
	self.data = datos

func setup_card_ui():
	if data is MonsterCardData:
		$Ataque.text = str(data.attack)
		$Vida.text = str(data.hp)
		$Vida.visible = true
		$Ataque.visible = true
		$MonsterTraits.visible= true
		$MonsterTraits.text = get_str_traits(data)
		$WeaponTraits.visible = false
	elif data is WeaponCardData:
		$Ataque.text = str(data.attack)
		$Vida.visible = false
		$MonsterTraits.visible = false
		$Ataque.visible = true
		$WeaponTraits.visible= true
		$WeaponTraits.text = get_str_traits(data)

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	update_visual_state()
	
func update_visual_state():
	match current_state:
		CardState.NORMAL:
			resaltadoDeAtaque.visible = false
			modulate = Color.WHITE
			self.set_rotation_degrees(0)
		CardState.SELECTED_FOR_ATTACK:
			resaltadoDeAtaque.visible = true
			resaltadoDeAtaque.add_theme_stylebox_override("panel", style_selected)
		CardState.CANNOT_ATTACK:
			resaltadoDeAtaque.visible = true
			resaltadoDeAtaque.add_theme_stylebox_override("panel", style_cannot_attack)
			self.set_rotation_degrees(90)
			modulate = Color(0.7, 0.7, 0.7)

func set_card_state(new_state: CardState):
	current_state = new_state
	
# Solo las armas en el WeaponGrid pueden ser seleccionadas
func can_be_double_clicked() -> bool:
	if not data is WeaponCardData:
		return false
	if parent_grid == null:
		return false
	# Verificar que el grid padre sea WeaponGrid
	var is_weapon_grid = parent_grid.get_script() and parent_grid.get_script().get_global_name() == "WeaponGrid"
	
	return is_weapon_grid

func can_be_selected_for_attack() -> bool:
	# Solo las armas en el PlayerWeaponGrid pueden atacar
	# Verificar que parent_grid sea específicamente PlayerWeaponGrid
	var is_in_player_grid = false
	if parent_grid != null:
		is_in_player_grid = parent_grid.get_script() and parent_grid.get_script().get_global_name() == "PlayerWeaponGrid"
	
	return data is WeaponCardData and can_attack and current_state != CardState.CANNOT_ATTACK and is_in_player_grid

func can_be_targeted() -> bool:
	return data is MonsterCardData

func select_for_attack():
	if can_be_selected_for_attack():
		set_card_state(CardState.SELECTED_FOR_ATTACK)
		emit_signal("card_selected_for_attack", self)

func target_for_attack(attacker: Carta):
	if can_be_targeted():
		emit_signal("card_targeted_for_attack", attacker, self)

func attack(target: Carta) -> bool:
	if not can_be_selected_for_attack() or not target.can_be_targeted():
		return false
	
	if data is WeaponCardData and target.data is MonsterCardData:
		var weapon_attack = data.attack
		
		for rasgo in data.traits:
			weapon_attack = rasgo.do_damage(self, target, weapon_attack)
		
		var player_damage = target.data.attack
		var player_damage_monster = target.data.attack
		
		for rasgo in data.traits:
			player_damage = rasgo.on_player_damage(player_damage, target)
		
		for rasgo in target.data.traits:
			player_damage_monster = rasgo.on_player_damage(player_damage_monster, target)
			
		if player_damage != 0:
			player_damage = player_damage_monster	
		
		var damage_to_monster = weapon_attack
		for rasgo in target.data.traits:
			damage_to_monster = rasgo.take_damage(self, target, damage_to_monster)
		
		var lifesteal_amount = 0
		for rasgo in data.traits:
			if rasgo is RobaVida:
				lifesteal_amount = rasgo.get_lifesteal_amount(weapon_attack, target)
		
		LifeManager.looseLife(player_damage)
		target.take_damage(weapon_attack)
		
		if lifesteal_amount > 0 && LifeManager.get_life() > 0:
			LifeManager.gainLife(lifesteal_amount)
		
		can_attack = false
		set_card_state(CardState.CANNOT_ATTACK)
		create_attack_effect(target)
		
		print("Arma atacó al monstruo por ", weapon_attack, " de daño")
		return true
	
	return false
	
func take_damage(damage: int, attacker: Carta = null):
	if data is MonsterCardData:
		for rasgo in data.traits:
			damage = rasgo.take_damage(attacker, self, damage)
		
		var monster_data = data as MonsterCardData
		monster_data.hp -= damage
		$Vida.text = str(monster_data.hp)
		create_damage_effect()
		
		if monster_data.hp <= 0:
			die()

func die():
	print("La carta ha muerto: ", name)
	emit_signal("card_died")
	create_death_effect()
	
	# Notificar al grid padre
	if parent_grid and parent_grid.has_method("update_on_card_death"):
		parent_grid.update_on_card_death(self)
	
	# Remover después de la animación
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func create_attack_effect(target: Carta):
	var tween = create_tween()
	var original_pos = global_position
	var target_pos = target.global_position
	
	tween.tween_property(self, "global_position", target_pos, 0.2)
	tween.tween_property(self, "global_position", original_pos, 0.2)

func create_damage_effect():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func create_death_effect():
	var tween = create_tween()
	tween.parallel().tween_property(self, "rotation", PI, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)

func reset_attack_ability():
	if data is WeaponCardData:
		can_attack = true
		set_card_state(CardState.NORMAL)
		print("Arma ", name, " reseteada - puede atacar")
		
func block_attack_ability():
	if data is WeaponCardData:
		can_attack = false
		set_card_state(CardState.CANNOT_ATTACK)
		print("Arma ", name, " bloqueada - no puede atacar")
		
func actLabel(label: Label):
	data.actLabel(label)

func reset_traits_for_new_turn():
	for rasgo in data.traits:
		rasgo.on_turn_reset(self)

func _on_area_mouse_entered() -> void:
	emit_signal("mouseSobreCarta", self)

func _on_area_mouse_exited() -> void:
	emit_signal("mouseFueraCarta", self)


@warning_ignore("unused_parameter")
func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click():
	# Solo procesar doble click si la carta puede ser seleccionada
	if not can_be_double_clicked():
		return
	
	click_count += 1
	click_timer = click_threshold
	
	if click_count >= 2:
		# Doble click detectado
		_on_double_click()
		click_count = 0
		click_timer = 0

func _on_double_click():
	print("Carta: Doble click detectado en ", name)
	emit_signal("card_double_clicked", self)

func get_monster_hps():
	var vidas:Array = []
	if data is MonsterCardData:
		vidas.append(data.hp)
		vidas.append(data.maxHp)
	return vidas

func get_str_traits(datos):
	var texto:String = ""
	for rasgo in datos.traits:
		texto += "* %s\n" % [rasgo.trait_name]
	return texto
