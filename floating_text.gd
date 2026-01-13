
extends Label

func _ready():
	var tween = create_tween().set_parallel(true)
	# Corrected transition and ease for Godot 4
	tween.tween_property(self, "position:y", position.y - 40, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	
	await get_tree().create_timer(0.8).timeout
	queue_free()

func setup(value: String, color: Color):
	self.text = value
	add_theme_color_override("font_color", color)
	add_theme_constant_override("outline_size", 8)
	add_theme_color_override("font_outline_color", Color.BLACK)
