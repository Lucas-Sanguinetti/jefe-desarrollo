class_name SpellEffects extends Node

# Este archivo estará listo para cuando quieras agregar animaciones

signal effect_started(effect_id: String, target)
signal effect_finished(effect_id: String, target)

# Diccionario de efectos: effect_id -> PackedScene de animación
var effect_animations: Dictionary = {}

func register_effect(effect_id: String, animation_scene: PackedScene):
	effect_animations[effect_id] = animation_scene

func play_effect(Hechizo: SpellCardData, target) -> void:
	effect_started.emit(Hechizo.effect_id, target)
	
	# Aquí irá la lógica de animaciones cuando las implementes
	if Hechizo.effect_id in effect_animations:
		var effect_instance = effect_animations[Hechizo.effect_id].instantiate()
		target.add_child(effect_instance)
		# Conectar señal de finalización, etc.
	
	# Por ahora, solo aplicar el efecto inmediatamente
	await get_tree().create_timer(0.1).timeout
	apply_spell_effect(Hechizo, target)
	
	effect_finished.emit(Hechizo.effect_id, target)

func apply_spell_effect(Hechizo: SpellCardData, target):
	# Primero intenta con efectos genéricos
	match Hechizo.effect_type:
		Hechizo.EffectType.DAMAGE:
			_apply_damage(target, Hechizo.effect_value)
		Hechizo.EffectType.HEAL:
			if LifeManager.get_life() < LifeManager.get_maxLife():
				print(LifeManager.get_life())
				_apply_heal(Hechizo.effect_value)
		
	_apply_special_effect(Hechizo, target)

func _apply_special_effect(Hechizo: SpellCardData, target):
	pass
	#match spell.effect_id:
		#"fireball":
			#target.take_damage(spell.effect_value)
			#target.apply_debuff("burning", 2, 3)
			#_spawn_fire_particles(target)
			#return true
			
func _apply_heal(value: int):
	LifeManager.gainLife(value)
	
func _apply_damage(target: CartaMonstruo, value:int):
	target.take_damage(value)
	
	
	
