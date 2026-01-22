extends EnemyBase

func _setup_enemy() -> void:
	super._setup_enemy()
	max_hp = 75
	chase_speed = 80
	roam_speed = 30.0 # Increase this (try 30-50)
	
	# Set the path to the SPECIFIC battle scene for this enemy
	# You can also change this directly in the Inspector!
	battle_scene_file = "res://Scenes/Battle scenes/ValeriusBattle.tscn"

func _on_battle_finished(victory: bool) -> void:
	get_tree().paused = false
	if victory:
		# Player killed the boss, go to the ending!
		get_tree().change_scene_to_file("res://Scenes/Cinematic scenes/outro_cinematic.tscn")
		die()
