extends Node

@onready var turn_button = $CanvasLayer/PasarTurno
@onready var turn_label = $CanvasLayer/ContadorTurno
@onready var card_manager = $CardManager
@onready var player_weapon_spawner = $PlayerWeaponSpawner
@onready var monster_spawner = $MonsterSpawner
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var card_info: Node2D = $InfoDisplay
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var pasar_turno: Button = $CanvasLayer/PasarTurno
@onready var spell_deck: SpellDeck = $SpellDeck
@onready var hand: Hand = $PlayerSpells
@onready var spell_effects: SpellEffects = $SpellEffects



var current_turn = 1.

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)
	LifeManager.vida_cambiada.connect(_on_vida_cambiada)
	hand.card_played.connect(_on_spell_cast)
	audio_stream_player.play()
	
	# Robar mano inicial
	var initial_cards = spell_deck.draw_initial_hand()
	for card in initial_cards:
		hand.add_card(card)

func _input(event):
	# DEBUG: Presionar T para transferir arma del almacén al jugador
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if weapon_manager and weapon_manager.has_method("transfer_random_weapon_to_player"):
			weapon_manager.transfer_random_weapon_to_player()
	

func _on_turn_button_pressed():
	current_turn += 1
	turn_label.text = "Turno: " + str(current_turn)
	pasar_turno.pressPlay()
	
	# Resetear habilidades de ataque de las armas EQUIPADAS
	reset_player_weapons()
	
	# Manejo de reseteo de armas y Monster Traits
	weapon_manager.reset_turn()
	reset_monster_traits()
	
	# Agregar hechizo tras finalizar turno
	if not hand.is_hand_full():
		var new_card = spell_deck.draw_turn_card()
		if new_card:
			hand.add_card(new_card)

func reset_player_weapons():
	player_weapon_spawner.reset_weapons_for_new_turn()

func block_player_weapons():
	player_weapon_spawner.block_weapons()

func _on_vida_cambiada(nueva_vida: int):
	if nueva_vida <= 0:
		block_player_weapons()
		print("Game Over - Sin vida, armas bloqueadas")
		$GameOver.show()
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Entidades/Main.tscn")
	
func reset_monster_traits():
	var monster_grid = monster_spawner.get_node("MonsterGrid")
	if not monster_grid:
		return
		
	var all_monsters = monster_grid.get_all_monsters()
	for monster in all_monsters:
		if monster.has_method("reset_traits_for_new_turn"):
			monster.reset_traits_for_new_turn()
			

func _on_spell_cast(hechizo: SpellCardData, target):
	#Para cuando agregue animaciones
	#await spell_effects.play_effect(spell, target)
	spell_effects.apply_spell_effect(hechizo,target)
	# Descartar el hechizo al mazo
	spell_deck.discard_card(hechizo)
