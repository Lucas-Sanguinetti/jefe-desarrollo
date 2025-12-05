extends Sprite2D

@export var nivel: int = 1 : set = set_nivel
@export var total_niveles: int = 5
@export var textura_base: Texture2D = preload("uid://bychpqody2ohj")

func _ready():
	set_nivel(nivel)

func set_nivel(value: int):
	nivel = clamp(value, 1, total_niveles)
	if not textura_base:
		return
	
	# Crear el AtlasTexture
	var atlas := AtlasTexture.new()
	atlas.atlas = textura_base

	var nivel_height := textura_base.get_height() / float(total_niveles)

	# Definir la región del nivel actual
	atlas.region = Rect2(
		0,                              # X (arranca arriba)
		(nivel - 1) * nivel_height,     # Y (nivel seleccionado)
		textura_base.get_width(),       # ancho
		nivel_height                    # alto
	)

	texture = atlas
