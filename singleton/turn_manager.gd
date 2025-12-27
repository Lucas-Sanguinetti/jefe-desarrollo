extends Node

# SEÑALES
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal game_end_for_turns()
#signal last_turn

# Restricciones activadas/desactivadas
signal restriction_changed(restriction_name: String, active: bool)

# ESTADO ACTUAL
var current_turn: int = 0

# RESTRICCIONES GLOBALES
var can_buy_weapons: bool = true    # Fundidor: bloquea compras
var can_heal: bool = true           # Antivida: bloquea curación
var forced_target: CartaMonstruo = null  # Protector: solo él puede ser atacado

# GESTIÓN DE TURNOS
func start_new_turn():
	current_turn += 1
	emit_signal("turn_started", current_turn)
	print("TurnManager: ===== TURNO %d INICIADO =====" % current_turn)
	if current_turn == 19:
		emit_signal("game_end_for_turns")
		

func end_turn():
	emit_signal("turn_ended", current_turn)
	print("TurnManager: ===== TURNO %d FINALIZADO =====" % current_turn)

func get_current_turn() -> int:
	return current_turn


func get_limit_low_level_turn() -> int:
	return 10

#boss turn
func get_limit_high_level_turn() -> int:
	return 18

# RESTRICCIONES
# ========================================
# 1. FUNDIDOR: ¿Se pueden comprar armas?
func can_buy_weapon() -> bool:
	if not can_buy_weapons:
		print("TurnManager: ⚠️ Compra bloqueada por Fundidor")
	return can_buy_weapons

# 2. ANTIVIDA: ¿Se puede curar?
func can_player_heal() -> bool:
	if not can_heal:
		print("TurnManager: ⚠️ Curación bloqueada por Antivida")
	return can_heal

# 3. PROTECTOR: ¿Este monstruo puede ser atacado?
func can_attack_monster(target: CartaMonstruo) -> bool:
	# Si hay un Protector activo, solo él puede ser atacado
	if forced_target and target != forced_target:
		print("TurnManager: ⚠️ Solo puedes atacar al Protector")
		return false
	return true


# ACTIVAR/DESACTIVAR RESTRICCIONES
# Los traits deberian llamar a estas funciones
# =================================================

# FUNDIDOR activa esto cuando entra a la mesa
func block_weapon_purchases(blocked: bool):
	can_buy_weapons = not blocked
	emit_signal("restriction_changed", "buy_weapons", can_buy_weapons)
	print("TurnManager: Compra de armas %s" % ("BLOQUEADA" if blocked else "DESBLOQUEADA"))
# ANTIVIDA activa esto cuando entra a la mesa
func block_healing(blocked: bool):
	can_heal = not blocked
	emit_signal("restriction_changed", "heal", can_heal)
	print("TurnManager: Curación %s" % ("BLOQUEADA" if blocked else "DESBLOQUEADA"))
# PROTECTOR activa esto cuando entra a la mesa
func set_forced_target(target: CartaMonstruo):
	forced_target = target
	if target:
		print("TurnManager: Solo se puede atacar a %s (Protector)" % target.name)
	else:
		print("TurnManager: Protector eliminado, ataques libres")

func clear_forced_target():
	forced_target = null

func has_forced_target() -> bool:
	return forced_target != null

# RESET (al reiniciar partida)
func reset():
	current_turn = 0
	can_buy_weapons = true
	can_heal = true
	forced_target = null
	print("TurnManager: Sistema reseteado")
