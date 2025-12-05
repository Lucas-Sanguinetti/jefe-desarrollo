extends Node


@export var weapons_data_cards: Array[WeaponCardData] 
@export var tutorialWeapon: WeaponCardData
var arma_tutorial_reset
var armas_reset

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	weapons_data_cards.shuffle()
	arma_tutorial_reset = tutorialWeapon.duplicate(true)
	armas_reset = weapons_data_cards.duplicate(true)

func draw():
	var weapon:WeaponCardData = weapons_data_cards[0]
	weapons_data_cards.remove_at(0)
	return weapon
	
func drawTutorial():
	return tutorialWeapon


func size():
	return weapons_data_cards.size()

func reset():
	tutorialWeapon = arma_tutorial_reset
	weapons_data_cards.clear()
	weapons_data_cards.append_array(armas_reset)
