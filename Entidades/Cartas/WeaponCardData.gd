extends CardData
class_name WeaponCardData

@export var attack: int

func actLabel(label: Label):
	var effect = "placeholder"
	label.text = "Ataque: %d \nEfecto: " % [attack] + effect
