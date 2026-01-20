# battle_camera.gd
extends Camera2D

var shake_strength: float = 0.0
var fade_speed: float = 5.0

func _ready():
	for character in get_tree().get_nodes_in_group("characters"):
		# This line prevents the crash by checking if the signal exists first
		if character.has_signal("damaged"):
			character.damaged.connect(_apply_shake)
		else:
			# This will tell you exactly which node is causing the trouble
			print("Skipping node: ", character.name, " because it has no damaged signal.")

func _process(delta):
	if shake_strength > 0:
		# Gradually reduce the shake strength
		shake_strength = lerp(shake_strength, 0.0, fade_speed * delta)
		# Apply random offset based on current strength
		offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		offset = Vector2.ZERO

func _apply_shake(intensity: float):
	shake_strength = intensity
