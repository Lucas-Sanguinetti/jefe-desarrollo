extends Node

@onready var turn_button = $CanvasLayer/PasarTurno
@onready var turn_label = $CanvasLayer/ContadorTurno
@onready var card_manager = $CardManager
@onready var player_weapon_spawner = $PlayerWeaponSpawner
@onready var monster_spawner = $MonsterSpawner
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var card_info: Node2D = $InfoDisplay

var current_turn = 1.

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)
	

func _input(event):
	# DEBUG: Presionar T para transferir arma del almacén al jugador
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if weapon_manager and weapon_manager.has_method("transfer_random_weapon_to_player"):
			weapon_manager.transfer_random_weapon_to_player()

func _on_turn_button_pressed():
	current_turn += 1
	turn_label.text = "Turno: " + str(current_turn)
	
	# Resetear habilidades de ataque de las armas EQUIPADAS
	if LifeManager.vida > 0:
		reset_player_weapons()
		print("Armas del jugador reseteadas - Pueden atacar nuevamente") #Debug
	else:
		block_player_weapons()
		print("Game Over - Todas las armas del jugador bloqueadas")#Debug
	
	print("Turno ", current_turn, " iniciado. Armas equipadas reseteadas.")#Debug

func reset_player_weapons():
	if player_weapon_spawner and player_weapon_spawner.has_method("reset_weapons_for_new_turn"):
		player_weapon_spawner.reset_weapons_for_new_turn()
		print("Reset ejecutado en PlayerWeaponSpawner")#Debug
	else:
		push_warning("No se encontró PlayerWeaponSpawner o no tiene el método reset_weapons_for_new_turn")#Debug

func block_player_weapons():
	if player_weapon_spawner and player_weapon_spawner.has_method("block_weapons"):
		player_weapon_spawner.block_weapons()
