extends Node
class_name Game
#Botones y labels
@onready var turn_button: Button = $Botones/PasarTurno
@onready var turn_label: Label = $Botones/ContadorTurno
@onready var sell_button: Button = $Botones/Vender
#Managers y spawners
@onready var card_manager = $CardManager
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var player_weapon_spawner = $PlayerWeaponSpawner
@onready var monster_spawner = $MonsterSpawner
#Hechizos
@onready var spell_deck: SpellDeck = $SpellDeck
@onready var hand: Hand = $PlayerSpells
@onready var spell_effects: SpellEffects = $SpellEffects
#Otros
@onready var card_info: Node2D = $InfoDisplay
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var pause_menu: PauseMenu = $PauseMenu
#Animaciones y Estilado
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var weapon_animation_manager: WeaponAnimationManager = $WeaponAnimationManager
@export var normal_style = preload("uid://dqvd7s1bo3s8v")
@export var ready_style = preload("uid://gtb6l3ilt1to")



var cartaSeleccionada
var current_turn = 1

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)
	turn_button.add_to_group("UI")
	sell_button.add_to_group("UI")
	
	monster_spawner.victory.connect(victory)
	
	# Conectar TurnManager
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.turn_ended.connect(_on_turn_ended)
	TurnManager.game_end_for_turns.connect(game_over)
	
	card_manager.armaSeleccionadaVenta.connect(_on_arma_seleccionada)
	card_manager.armaDeseleccionada.connect(_on_arma_deseleccionada)
	card_manager.armaUsada.connect(_on_arma_usada)
	
	LifeManager.vida_cambiada.connect(_on_vida_cambiada)
	hand.card_played.connect(_on_spell_cast)
	audio_stream_player.play()
	
	# Conectar señales PauseMenu
	if pause_menu:
		pause_menu.resume_pressed.connect(_on_pause_resume)
		pause_menu.restart_pressed.connect(_on_pause_restart)
		pause_menu.main_menu_pressed.connect(_on_pause_main_menu)
	
	_setup_weapon_animations()
	
	# Robar mano inicial
	var initial_cards = spell_deck.draw_initial_hand()
	for card in initial_cards:
		hand.add_card(card)
	TurnManager.start_new_turn()

func _on_turn_started(turn_number: int):
	print("Game: ===== TURNO %d =====" % turn_number)
	turn_label.text = "TURNO: " + str(turn_number) + "/12"
	_spawn_cards()
	reset_player_weapons()
	reset_monster_traits()
	_apply_normal_style()

func _on_arma_usada():
	var player_weapons = player_weapon_spawner.player_grid.get_all_weapons()
	var finish_turn = true
	for weapon in player_weapons:
		if weapon.is_charged(): 
			finish_turn = false
			break
	if finish_turn:
		_apply_ready_style()
	else:
		_apply_normal_style()

func _on_turn_ended(turn_number: int):
	print("Game: Turno %d finalizado" % turn_number)
	await get_tree().create_timer(0.5).timeout
	TurnManager.start_new_turn()

func _spawn_cards():
	# Invocar monstruo
	monster_spawner.draw()
	# Robar hechizo
	if not hand.is_full():
		var new_card = spell_deck.draw_turn_card()
		if new_card:
			hand.add_card(new_card)

func _on_turn_button_pressed():
	TurnManager.end_turn()
	turn_button.pressPlay()

# ============================================
# RESETEOS
# ============================================
func reset_player_weapons():
	player_weapon_spawner.reset_weapons_for_new_turn()

func block_player_weapons():
	player_weapon_spawner.block_weapons()

func reset_monster_traits():
	var monster_grid = monster_spawner.get_node("MonsterGrid")
	if not monster_grid:
		return
		
	var all_monsters = monster_grid.get_all_monsters()
	for monster in all_monsters:
		if monster.has_method("reset_traits_for_new_turn"):
			monster.reset_traits_for_new_turn()
#Vida
func _on_vida_cambiada(nueva_vida: int):
	var vida_previa = LifeManager.get_vidaAnterior()
	if nueva_vida < vida_previa:
		#push_error("Recibiste daño neto: %d → %d" % [vida_previa, nueva_vida])
		canvas_layer.damage()  # Shader rojo
	elif nueva_vida > vida_previa:
		#push_warning("Te curaste: %d → %d" % [vida_previa, nueva_vida])
		canvas_layer.curar() 
		
	if nueva_vida <= 0:
		game_over()
		
#Game Over
func game_over():
	block_player_weapons()
	$Ventanas/GameOver.visible = true
	await get_tree().create_timer(2.0).timeout
	_reset_game()
	get_tree().change_scene_to_file("res://Entidades/main.tscn")
	
#Victoria
func victory():
	if LifeManager.get_life() > 0 :
		block_player_weapons()
		$Ventanas/Victory.visible = true
		await get_tree().create_timer(2.0).timeout
		_reset_game()
		get_tree().change_scene_to_file("res://Entidades/main.tscn")
	
#Resear Juego
func _reset_game():
	LifeManager.reset()
	MoneyManager.reset()
	MonsterDeck.reset()
	WeaponDeck.reset()
	TurnManager.reset()
	
#Animaciones
func _setup_weapon_animations():
	if not weapon_animation_manager:
		#push_error("Game: No se encontró WeaponAnimationManager")
		return
	
	# Registrar animación de Disparo
	weapon_animation_manager.register_animation("Disparo", 
		weapon_animation_manager.animate_disparo)

	
#Hechizos
func _on_spell_cast(card:CartaHechizo, hechizo: SpellCardData, target):
	var success = spell_effects.apply_spell_effect(hechizo,target)
	if success:
		card.pay_cost()
		card.mark_as_used()
		hand.remove_card(card)
		spell_deck.discard_card(hechizo)
	else:
		print("Game: Hechizo '%s' falló - NO se descarta" % hechizo.name)
	if hechizo.effect_id == "bateria":
		_apply_normal_style()

# Venta de armas
# ============================================
func _on_arma_seleccionada(carta:CartaArma):
	sell_button.set_disabled(false)
	cartaSeleccionada = carta
	
func _on_arma_deseleccionada():
	sell_button.set_disabled(true)
	cartaSeleccionada = null

func _on_sell_button_pressed():
	if player_weapon_spawner.cantidad_armas() > 1:
		sell_button.pressSell(cartaSeleccionada)
		weapon_manager.venderArma(cartaSeleccionada)
	sell_button.set_disabled(true)

# Funciones del Menu
# ============================================
func _on_pause_resume():
	pass
	
func _on_pause_restart():
	_reset_game()
	get_tree().reload_current_scene()
	
func _on_pause_main_menu():
	get_tree().change_scene_to_file("res://Entidades/main.tscn")


func _on_timer_timeout() -> void:
	canvas_layer.hide()

func _on_curar_timer_timeout() -> void:
	canvas_layer.hide()

func _apply_ready_style():
	if ready_style:
		turn_button.add_theme_stylebox_override("normal", ready_style)


func _apply_normal_style():
	if normal_style:
		turn_button.add_theme_stylebox_override("normal", normal_style)
