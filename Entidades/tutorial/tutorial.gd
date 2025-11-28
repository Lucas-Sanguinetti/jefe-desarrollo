extends Node

@onready var turn_button = $CanvasLayer/PasarTurno
@onready var turn_label = $CanvasLayer/ContadorTurno
@onready var card_manager = $CardManager
@onready var player_weapon_spawner = $PlayerWeaponSpawner
@onready var monster_spawner = $MonsterSpawner
@onready var weapon_manager = $WeaponManager
@onready var card_info: Node2D = $InfoDisplay


@export var titleScreen: PackedScene

var armaSelected = false
var current_turn = 1.

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)
	LifeManager.vida_cambiada.connect(_on_vida_cambiada)
	card_manager.armaSeleccionada.connect(_on_arma_seleccionada)
	card_manager.armaUsada.connect(_on_arma_usada)
	weapon_manager.armaTransferida.connect(_on_arma_transferida)
	#texto
	$Label_tut1.visible = true
	$Label_tut2.visible = false
	$Label_tut3.visible = false
	$Label_tut4.visible = false
	
	#sombras
	$sombra1_tut1.visible = true
	$sombra2_tut1.visible = true 
	$sombra1_tut2.visible = false 
	$sombra2_tut2.visible = false 
	$sombra1_tut3.visible = false 
	$sombra2_tut3.visible = false 
	$sombra3_tut3.visible = false 
	$sombra1_tut4.visible = false 
	$sombra2_tut4.visible = false
	

func _on_turn_button_pressed():
	LifeManager.reset()
	MoneyManager.reset()
	MonsterDeck.reset()
	WeaponDeck.reset()
	get_tree().change_scene_to_file("res://Entidades/main.tscn")

func reset_player_weapons():
	player_weapon_spawner.reset_weapons_for_new_turn()

func block_player_weapons():
	player_weapon_spawner.block_weapons()

func _on_vida_cambiada(nueva_vida: int):
	if nueva_vida <= 0:
		block_player_weapons()
		print("Game Over - Sin vida, armas bloqueadas")
	
func reset_monster_traits():
	var monster_grid = monster_spawner.get_node_or_null("MonsterGrid")
	if not monster_grid:
		return
		
	var all_monsters = monster_grid.get_all_monsters()
	for monster in all_monsters:
		if monster.has_method("reset_traits_for_new_turn"):
			monster.reset_traits_for_new_turn()

func _on_arma_seleccionada():
	$Label_tut1.visible = false
	$Label_tut2.visible = true
	$sombra1_tut1.visible = false
	$sombra2_tut1.visible = false 
	$sombra1_tut2.visible = true 
	$sombra2_tut2.visible = true
	
func _on_arma_usada():
	$Label_tut2.visible = false
	$Label_tut3.visible = true
	$sombra1_tut2.visible = false 
	$sombra2_tut2.visible = false
	$sombra1_tut3.visible = true 
	$sombra2_tut3.visible = true 
	$sombra3_tut3.visible = true

func _on_arma_transferida():
	$Label_tut3.visible = false
	$Label_tut4.visible = true
	$sombra1_tut3.visible = false 
	$sombra2_tut3.visible = false 
	$sombra3_tut3.visible = false
	$sombra1_tut4.visible = true 
	$sombra2_tut4.visible = true
