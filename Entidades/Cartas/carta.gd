extends Node2D
class_name Carta

@export var data: CardData
@export var can_attack: bool = true 

var grid_pos:Vector2
@onready var sprite: Sprite2D = $Sprite
@onready var resaltadoDeAtaque: Panel = $Resaltado  # Panel para resaltado de ataque

signal mouseSobreCarta
signal mouseFueraCarta
signal card_selected_for_attack
signal card_targeted_for_attack

enum CardState {
	NORMAL,
	SELECTED_FOR_ATTACK,
	CANNOT_ATTACK
}

var current_state: CardState = CardState.NORMAL

func _ready() -> void:
	sprite.texture = data.sprite
	
	if not has_node("resaltadoDeAtaque"):
		resaltadoDeAtaque = Panel.new()
		resaltadoDeAtaque.name = "resaltadoDeAtaque"
		resaltadoDeAtaque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resaltadoDeAtaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		resaltadoDeAtaque.add_theme_color_override("resaltado",Color(1, 0, 0, 0.3) )
		resaltadoDeAtaque.visible = false
		add_child(resaltadoDeAtaque)
	
	setup_card_ui()
	
	if get_parent().has_method("connect_combat_signals"):
		get_parent().connect_combat_signals(self)
		get_parent().connect_card_signals(self)

func setup(data: CardData):
	self.data = data

func setup_card_ui():
	# Lógica condicional según el tipo de carta
	if data is MonsterCardData:
		$Ataque.text = str(data.attack)
		$Vida.text = str(data.hp)
		$Vida.visible = true
		$Ataque.visible = true
	elif data is WeaponCardData:
		$Ataque.text = str(data.attack)
		$Vida.visible = false
		$Ataque.visible = true

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
			resaltadoDeAtaque.add_theme_color_override("resaltado",Color(0, 1, 0, 0.3))
		CardState.CANNOT_ATTACK:
			resaltadoDeAtaque.visible = false
			self.set_rotation_degrees(90)
			modulate = Color(0.5, 0.5, 0.5)  # Gris para no puede atacar

func set_card_state(new_state: CardState):
	current_state = new_state

func can_be_selected_for_attack() -> bool:
	return data is WeaponCardData and can_attack and current_state != CardState.CANNOT_ATTACK

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
		# Realizar el ataque
		var weapon_attack = data.attack
		target.take_damage(weapon_attack)
		LifeManager.looseLife(target.data.attack)
		LifeManager.life()
		
		can_attack = false # El arma ya no puede atacar este turno
		
		set_card_state(CardState.CANNOT_ATTACK)

		create_attack_effect(target) # Efecto visual de ataque
		
		print("Arma atacó al monstruo por ", weapon_attack, " de daño")
		return true
	
	return false
	
func take_damage(damage: int):
	if data is MonsterCardData:
		var monster_data = data as MonsterCardData
		monster_data.hp -= damage
		$Vida.text = str(monster_data.hp)

		create_damage_effect() # Efecto visual de daño
		# Verificar si el monstruo murió
		if monster_data.hp <= 0:
			die()

func die():
	print("El monstruo ha muerto")
	
	create_death_effect() # Efecto de muerte
	
	# Remover de la grilla 
	
	
	# Remover la carta de la escena después del efecto
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func create_attack_effect(target: Carta):
	# Efecto visual simple de ataque
	var tween = create_tween()
	var original_pos = global_position
	var target_pos = target.global_position
	
	# Mover hacia el objetivo y regresar
	tween.tween_property(self, "global_position", target_pos, 0.2)
	tween.tween_property(self, "global_position", original_pos, 0.2)

func create_damage_effect():
	# Efecto visual de daño recibido
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func create_death_effect():
	# Efecto visual de muerte
	var tween = create_tween()
	tween.parallel().tween_property(self, "rotation", PI, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.5)

func reset_attack_ability():
	# Restaurar la capacidad de ataque (llamar al inicio de cada turno)
	if data is WeaponCardData:
		can_attack = true
		set_card_state(CardState.NORMAL)
		
func _on_area_mouse_entered() -> void:
	emit_signal("mouseSobreCarta",self)

func _on_area_mouse_exited() -> void:
	emit_signal("mouseFueraCarta",self)
	
	
