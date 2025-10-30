extends Button


@onready var press: AudioStreamPlayer = $press

func pressPlay():
	press.play()
