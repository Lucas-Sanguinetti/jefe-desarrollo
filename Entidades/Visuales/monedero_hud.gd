extends Node2D

@onready var label = $Monedas
@onready var sprite = $Sprite2D
@onready var coin_sprite: Sprite2D = $Coin
var old_value = 0
var active_tween : Tween
func _ready():
	MoneyManager.connect("monedero_cambiado", Callable(self, "_on_monedero_cambiado"))
	
	if coin_sprite:
		coin_sprite.scale = Vector2(2, 2)
		coin_sprite.modulate = Color.WHITE
		
	_on_monedero_cambiado(MoneyManager.monedas)

func _on_monedero_cambiado(valor: int):
	label.text = str(valor)
	
	if valor > old_value and coin_sprite:
		_animate_coin_gain()
	old_value = valor

func _animate_coin_gain():
	if active_tween:
		active_tween.kill()

	coin_sprite.scale = Vector2(2, 2)
	coin_sprite.modulate = Color.WHITE

	active_tween = create_tween()
	var tween = active_tween
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Subir
	tween.tween_property(coin_sprite, "scale", Vector2(3, 3), 0.3)
	tween.tween_property(coin_sprite, "modulate", Color(2, 2, 1.5), 0.3)

	# Pausa mínima para forzar secuencia (evita el bug)
	tween.tween_interval(0.01)

	# Bajar
	tween.tween_property(coin_sprite, "scale", Vector2(2, 2), 0.3)
	tween.tween_property(coin_sprite, "modulate", Color.WHITE, 0.3)

	await tween.finished
