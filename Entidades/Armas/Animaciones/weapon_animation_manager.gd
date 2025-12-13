extends Node
class_name WeaponAnimationManager

# SEÑALES
signal animation_started(weapon: CartaArma, animation_type: String)
signal projectile_hit(target: Carta)

# REGISTRO DE ANIMACIONES
var registered_animations: Dictionary = {}

# SCENE DEL PROYECTIL
var projectile_scene: PackedScene = preload("uid://pwbwd62peuya")

func _ready():
	add_to_group("WeaponAnimationManager")
	print("WeaponAnimationManager: Inicializado")

# ============================================
# REGISTRO DE ANIMACIONES
# ============================================
func register_animation(trait_name: String, callback: Callable):
	registered_animations[trait_name] = callback
	print("WeaponAnimationManager: Registrada animación '%s'" % trait_name)

func has_animation(trait_name: String) -> bool:
	return trait_name in registered_animations

# ============================================
# EJECUTAR ANIMACIÓN
# ============================================
func play_attack_animation(weapon: CartaArma, target: Carta) -> bool:
	if not weapon or not weapon.data:
		return false
	
	var weapon_data = weapon.data as WeaponCardData
	if not weapon_data:
		return false
	
	# Buscar trait con animación
	for rasgo in weapon_data.traits:
		var trait_name = rasgo.get_script().get_global_name()
		
		if has_animation(trait_name):
			emit_signal("animation_started", weapon, trait_name)
			
			var callback = registered_animations[trait_name]
			callback.call(weapon, target, self)
			
			return true
	
	return false

# ============================================
# ANIMACIÓN: DISPARO
# ============================================
func animate_disparo(weapon: CartaArma, target: Carta, manager: WeaponAnimationManager):
	var original_position = weapon.global_position
	var target_position = target.global_position
	# Calcular posición de disparo:
	# - Misma X que el objetivo (alineado con la columna del monstruo)
	# - Y debajo del grid de monstruos (aproximadamente donde está la mano del jugador)
	var shoot_position = Vector2(target_position.x, original_position.y - 120)
	
	# FASE 1: Mover arma a posición de disparo (al pie de la columna del monstruo)
	var tween = weapon.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(weapon, "global_position", shoot_position, 0.25)
	
	# FASE 2: Pequeña pausa y disparar proyectil
	tween.tween_interval(0.1)
	tween.tween_callback(func(): 
		manager._spawn_projectile(weapon, target)
	)
	
	# Esperar a que el proyectil llegue
	tween.tween_interval(0.4)
	
	# FASE 3: Volver a posición original
	tween.tween_property(weapon, "global_position", original_position, 0.25)
	


# ============================================
# SPAWN DE PROYECTIL
# ============================================
func _spawn_projectile(weapon: CartaArma, target: Carta):
	if not projectile_scene:
		push_error("WeaponAnimationManager: No hay escena de proyectil configurada")
		return
	
	var projectile = projectile_scene.instantiate()
	
	# Agregar al árbol (en el mismo nivel que las cartas)
	var game_node = get_tree().current_scene
	game_node.add_child(projectile)
	
	# Posicionar en el arma
	projectile.global_position = weapon.global_position
	
	# Configurar el proyectil
	if projectile.has_method("setup"):
		projectile.setup(weapon, target, self)
	
	print("WeaponAnimationManager: Proyectil disparado desde %s hacia %s" % [weapon.name, target.name])

# ============================================
# CALLBACK: IMPACTO DE PROYECTIL
# ============================================
func on_projectile_hit(target: Carta):
	emit_signal("projectile_hit", target)
	
	# Mostrar efecto de impacto
	if target.has_method("create_damage_effect"):
		target.create_damage_effect()

# ============================================
# ANIMACIÓN GENÉRICA: MELEE
# ============================================
func animate_melee_attack(weapon: CartaArma, target: Carta, manager: WeaponAnimationManager):

	var original_position = weapon.global_position
	var target_position = target.global_position
	
	var tween = weapon.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Ir hacia el enemigo
	tween.tween_property(weapon, "global_position", target_position, 0.2)
	
	# Efecto de impacto
	tween.tween_callback(func():
		if target.has_method("create_damage_effect"):
			target.create_damage_effect()
		manager.emit_signal("projectile_hit", target)
	)
	
	# Volver a posición original
	tween.tween_property(weapon, "global_position", original_position, 0.2)
	
	# Finalizar
	tween.tween_callback(func():
		manager.emit_signal("animation_finished", weapon, "Melee")
	)
