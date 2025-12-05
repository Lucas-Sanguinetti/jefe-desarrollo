extends Node2D
class_name Projectile

# REFERENCIAS
var weapon: CartaArma
var target: Carta
var animation_manager: WeaponAnimationManager

# CONFIGURACIÓN
@export var speed: float = 800.0  # Píxeles por segundo

# VISUAL
@onready var sprite: Sprite2D = $Sprite2D

# ESTADO
var velocity: Vector2 = Vector2.ZERO
var has_hit: bool = false

func setup(from_weapon: CartaArma, to_target: Carta, manager: WeaponAnimationManager):
	weapon = from_weapon
	target = to_target
	animation_manager = manager
	
	if not target:
		queue_free()
		return
	
	# Calcular dirección hacia el objetivo
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Rotar el sprite hacia el objetivo
	rotation = direction.angle()
	
	# Color según elemento del arma (opcional)
	_apply_element_color()

func _apply_element_color():
	if not weapon or not sprite:
		return
	
	match weapon.element:
		WeaponCardData.ElementType.FIRE:
			sprite.modulate = Color(1.0, 0.3, 0.0)  # Naranja
		WeaponCardData.ElementType.ICE:
			sprite.modulate = Color(0.3, 0.7, 1.0)  # Azul claro
		WeaponCardData.ElementType.POISON:
			sprite.modulate = Color(0.5, 0.0, 0.8)  # Púrpura
		WeaponCardData.ElementType.NATURE:
			sprite.modulate = Color(0.2, 0.8, 0.2)  # Verde
		WeaponCardData.ElementType.ELECTRIC:
			sprite.modulate = Color(1.0, 1.0, 0.0)  # Amarillo
		WeaponCardData.ElementType.WATER:
			sprite.modulate = Color(0.2, 0.4, 1.0)  # Azul
		WeaponCardData.ElementType.DARK:
			sprite.modulate = Color(0.101, 0.105, 0.117, 1.0)
		WeaponCardData.ElementType.EARTH:
			sprite.modulate = Color(0.42, 0.258, 0.102, 1.0)
		WeaponCardData.ElementType.WIND:
			sprite.modulate = Color(0.36, 0.98, 0.428, 1.0)
		_:
			sprite.modulate = Color.WHITE

func _process(delta: float):
	if has_hit:
		return
	
	if not is_instance_valid(target):
		_destroy()
		return
	
	# Mover hacia el objetivo
	global_position += velocity * delta
	
	# Verificar si llegó al objetivo
	var distance_to_target = global_position.distance_to(target.global_position)
	
	if distance_to_target < 20.0:  # Umbral de impacto
		_hit_target()

func _hit_target():
	if has_hit:
		return
	
	has_hit = true
	
	# Notificar al animation manager
	if animation_manager:
		animation_manager.on_projectile_hit(target)
	
	# Efecto de impacto
	_create_impact_effect()
	
	# Destruir el proyectil
	_destroy()

func _create_impact_effect():

	# Destello rápido
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.1)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.1)

func _destroy():

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)
