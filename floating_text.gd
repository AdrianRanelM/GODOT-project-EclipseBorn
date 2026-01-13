extends Label

func _ready():
	# Create a tween to handle the "floating" and "fading"
	var tween = create_tween().set_parallel(true)
	
	# Move up by 40 pixels over 1 second
	tween.tween_property(self, "position:y", position.y - 40, 1.0)
	# Fade out to transparent
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# Automatically delete the text once the tween finishes
	tween.chain().tween_callback(queue_free)

func setup(value: String, color: Color):
	text = value
	modulate = color
