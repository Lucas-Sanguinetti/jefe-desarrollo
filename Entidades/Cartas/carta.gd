extends Node2D
class_name Carta

@export var data: CardData

@onready var sprite: Sprite2D = $Sprite
signal mouseSobreCarta
signal mouseFueraCarta

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_card_signals(self)
	sprite.texture = data.sprite
	
	 #Lógica condicional según el tipo de carta
	if data is MonsterCardData:
		$Panel/Ataque.text = str(data.attack)
		$Panel/Vida.text = str(data.hp)
		$Panel/Vida.visible = true
		$Panel/Ataque.visible = true
	elif data is WeaponCardData:
		$Panel/Ataque.text = str(data.attack)
		$Panel/Vida.visible = false
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_mouse_entered() -> void:
	emit_signal("mouseSobreCarta",self)

func _on_area_mouse_exited() -> void:
	emit_signal("mouseFueraCarta",self)
	
	
