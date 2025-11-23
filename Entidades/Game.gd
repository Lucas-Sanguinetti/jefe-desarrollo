extends Node

#Botones y labels
@onready var turn_button = $CanvasLayer/PasarTurno
@onready var turn_label = $CanvasLayer/ContadorTurno
@onready var sell_button: Button = $CanvasLayer/Vender
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

var cartaSeleccionada
var current_turn = 1

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)
	turn_button.add_to_group("UI")
	sell_button.add_to_group("UI")
	
	# Conectar TurnManager
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.turn_ended.connect(_on_turn_ended)
	
	card_manager.armaSeleccionadaVenta.connect(_on_arma_seleccionada)
	card_manager.armaDeseleccionada.connect(_on_arma_deseleccionada)
	
	LifeManager.vida_cambiada.connect(_on_vida_cambiada)
	hand.card_played.connect(_on_spell_cast)
	audio_stream_player.play()
	
	# Robar mano inicial
	var initial_cards = spell_deck.draw_initial_hand()
	for card in initial_cards:
		hand.add_card(card)
	TurnManager.start_new_turn()

func _on_turn_started(turn_number: int):
	print("Game: ===== TURNO %d =====" % turn_number)
	turn_label.text = "TURNO: " + str(turn_number)
	_spawn_cards()
	reset_player_weapons()
	reset_monster_traits()

func _on_turn_ended(turn_number: int):
	print("Game: Turno %d finalizado" % turn_number)
	await get_tree().create_timer(0.5).timeout
	TurnManager.start_new_turn()

func _spawn_cards():
	# Invocar monstruo
	monster_spawner.draw()
	
	# Invocar arma en WeaponGrid
	if WeaponDeck.size() > 0:
		var weapon = WeaponDeck.draw()
		if weapon:
			var weapon_grid = weapon_manager.weapon_grid
			if weapon_grid and not weapon_grid.get_empty_slots().is_empty():
				weapon_grid.invoke_random_piece(weapon)
	
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
	if nueva_vida <= 0:
		block_player_weapons()
		$CanvasLayer2/GameOver.show()
		await get_tree().create_timer(2.0).timeout
		_reset_game()
#Resear Juego
func _reset_game():
	LifeManager.reset()
	MoneyManager.reset()
	MonsterDeck.reset()
	WeaponDeck.reset()
	TurnManager.reset()
	get_tree().change_scene_to_file("res://Entidades/Main.tscn")
#Hechizos
func _on_spell_cast(hechizo: SpellCardData, target):
	spell_effects.apply_spell_effect(hechizo,target)
	spell_deck.discard_card(hechizo)

# ============================================
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
