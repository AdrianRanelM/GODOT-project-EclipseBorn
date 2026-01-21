extends BaseScene

func _ready() -> void:
	super()
	
	if scene_manager.player:
		add_child(scene_manager.player)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		scene_manager.change_scene("res://Scenes/valerius_room.tscn", "SpawnPoint")
