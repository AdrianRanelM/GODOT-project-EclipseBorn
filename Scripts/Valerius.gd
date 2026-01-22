extends EnemyBase

func _setup_enemy() -> void:
	# Run the base logic first
	super._setup_enemy()
	
	# Customize this specific enemy
	max_hp = 75
	chase_speed = 90.0
	roam_speed = 40.0
	
	# Set the path to the SPECIFIC battle scene for this enemy
	# You can also change this directly in the Inspector!
	battle_scene_file = "res://Scenes/Battle scenes/ValeriusBattle.tscn"
