extends Node
class_name Tutorial

@onready var turn_button = $Botones/PasarTurno
@onready var turn_label = $Botones/ContadorTurno
#Managers y spawners
@onready var card_manager = $CardManager
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var player_weapon_spawner = $PlayerWeaponSpawner
@onready var monster_spawner = $MonsterSpawner

#Hechizos
@onready var spell_deck: SpellDeck = $SpellDeck
@onready var hand: Hand = $PlayerSpells
@onready var spell_effects: SpellEffects = $SpellEffects

@onready var ability_system: AbilitySystem = $AbilitySystem

@onready var pause_menu: PauseMenu = $PauseMenu

#Paneles
@onready var panel_invisible: Panel = $Vida/PanelInvisible

var stepArma = true
var stepHabilidad = true
var current_turn = 1.

func _ready() -> void:
	turn_button.pressed.connect(_on_turn_button_pressed)
	LifeManager.vida_cambiada.connect(_on_vida_cambiada)
	card_manager.armaSeleccionada.connect(_on_arma_seleccionada)
	card_manager.armaDeseleccionada.connect(_on_arma_esdseleccionada)
	card_manager.armaUsada.connect(_on_arma_usada)
	weapon_manager.armaTransferida.connect(_on_arma_transferida)
	ability_system.ability_executed.connect(_on_ability_used)
	spell_effects.effect_finished.connect(_on_spell_used)
	hand.card_played.connect(_on_spell_cast)
	
	if pause_menu:
		pause_menu.resume_pressed.connect(_on_pause_resume)
		pause_menu.restart_pressed.connect(_on_pause_restart)
		pause_menu.main_menu_pressed.connect(_on_pause_main_menu)
	
	#paneles y carteles
	panel_invisible.tutorial_click.connect(_on_vida_tutorial)
	$SelecArma.visible = true
	$Ataque.visible = false
	$Vida.visible = false
	$Compra.visible = false
	$Habilidad.visible = false
	$Hechizos.visible = false
	$TerminarTutorial.visible = false
	
	monster_spawner.place_monster_tutorial()
# Funcionalidad necesaria para el progreso y finalizado

func _reset_game():
	LifeManager.reset()
	MoneyManager.reset()
	MonsterDeck.reset()
	WeaponDeck.reset()
	TurnManager.reset()

func _on_turn_button_pressed():
	_reset_game()
	get_tree().change_scene_to_file("res://Entidades/main.tscn")

func reset_player_weapons():
	player_weapon_spawner.reset_weapons_for_new_turn()

func block_player_weapons():
	player_weapon_spawner.block_weapons()

func _on_vida_cambiada(nueva_vida: int):
	if nueva_vida <= 0:
		block_player_weapons()
	
func reset_monster_traits():
	var monster_grid = monster_spawner.get_node_or_null("MonsterGrid")
	if not monster_grid:
		return
		
	var all_monsters = monster_grid.get_all_monsters()
	for monster in all_monsters:
		if monster.has_method("reset_traits_for_new_turn"):
			monster.reset_traits_for_new_turn()

func _on_spell_cast(card:CartaHechizo, hechizo: SpellCardData, target):
	var success = spell_effects.apply_spell_effect(hechizo,target)
	print("%s", success)
	if success:
		card.pay_cost()
		card.mark_as_used()
		hand.remove_card(card)
		spell_deck.discard_card(hechizo)

# Funciones de seguimiento del tutorial
func _on_arma_seleccionada():
	if not stepHabilidad:
		return
	$SelecArma.visible = false
	$Ataque.visible = true
	

func _on_arma_esdseleccionada():
	if not stepArma:
		return
	$SelecArma.visible = true
	$Ataque.visible = false

func _on_arma_usada():
	stepArma = false
	ocultar_canva_arma()
	$SelecArma.visible = false
	$Ataque.visible = false
	panel_invisible.visible = false
	$Vida.visible = true
	await get_tree().create_timer(2.0).timeout
	panel_invisible.visible = true

func _on_vida_tutorial():
	ocultar_canva_arma()
	$Ataque.visible = false
	$SelecArma.visible = false
	$Vida.visible = false
	$Compra.visible = true

func _on_arma_transferida():
	stepHabilidad = false
	ocultar_canva_arma()
	$Compra.visible = false
	$Habilidad.visible = true
	
func _on_ability_used(_weapon, _ability, _target):
	ocultar_canva_arma()
	$Habilidad.visible = false
	$Hechizos.visible = true
	
func _on_spell_used(_effect_id, _target):
	ocultar_canva_arma()
	$Hechizos.visible = false
	$TerminarTutorial.visible = true

func ocultar_canva_arma():
	$SelecArma/ColorArma.visible = false
	$SelecArma/ColorArma2.visible = false
	$SelecArma/ColorArma3.visible = false
# Funciones del Menu
# ============================================
func _on_pause_resume():
	pass
	
func _on_pause_restart():
	_reset_game()
	get_tree().reload_current_scene()
	
func _on_pause_main_menu():
	get_tree().change_scene_to_file("res://Entidades/main.tscn")
