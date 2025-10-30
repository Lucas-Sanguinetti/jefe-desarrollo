extends Node2D

signal monedero_cambiado(cantMonedas)

var monedas: int = 0 
var monedasMax:int = 1000

func set_monedas(value):
	monedas = clamp(value, 0, monedasMax)
	emit_signal("monedero_cambiado", monedas)

func ganarMonedas(cant: int ):
	set_monedas(monedas + cant)
	
func perderMonedas(cant: int):
	set_monedas(monedas - cant)

func get_money():
	return monedas

#Debug
func money():
	print(monedas)
	
func get_maxMoney():
	return monedasMax
