extends Node2D

@onready var label = $Monedas
@onready var sprite = $Sprite2D

func _ready():
	MoneyManager.connect("monedero_cambiado", Callable(self, "_on_monedero_cambiado"))
	# mostrar estado inicial
	_on_monedero_cambiado(MoneyManager.monedas)

func _on_monedero_cambiado(valor: int):
	label.text = str(valor)
	
