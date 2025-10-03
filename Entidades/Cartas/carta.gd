extends Node2D
class_name Carta

@export var data: CardData
@export var can_attack: bool = true 

var grid_pos: Vector2
var parent_grid: Node2D = null  # Referencia al grid padre
@onready var sprite: TextureRect = $Sprite
var resaltadoDeAtaque: Panel
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat  
var style_cannot_attack: StyleBoxFlat

signal mouseSobreCarta
signal mouseFueraCarta
signal card_selected_for_attack
signal card_targeted_for_attack
signal card_died

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

func connect_to_manager():
	var manager = get_node_or_null("/root/Main/CardManager")
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
	elif data is WeaponCardData:
		$Ataque.text = str(data.attack)
		$Vida.visible = false
		$Ataque.visible = true

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
		target.take_damage(weapon_attack)
		LifeManager.looseLife(target.data.attack)
		LifeManager.life()
		
		can_attack = false
		set_card_state(CardState.CANNOT_ATTACK)
		create_attack_effect(target)
		
		print("Arma atacó al monstruo por ", weapon_attack, " de daño")
		return true
	
	return false
	
func take_damage(damage: int):
	if data is MonsterCardData:
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

func _on_area_mouse_entered() -> void:
	emit_signal("mouseSobreCarta", self)

func _on_area_mouse_exited() -> void:
	emit_signal("mouseFueraCarta", self)
