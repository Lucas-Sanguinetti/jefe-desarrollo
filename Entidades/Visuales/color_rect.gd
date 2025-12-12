extends ColorRect





func action():
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/intensity", 1.0, 0.1)
	tween.tween_property(material, "shader_parameter/intensity", 0.0, 0.2)
