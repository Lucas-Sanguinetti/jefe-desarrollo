extends Button




func pressSell(carta:CartaArma):
	if(carta.nivel <= 3):
		MoneyManager.ganarMonedas(1)
	if(carta.nivel >= 4):
		MoneyManager.ganarMonedas(2)
	
