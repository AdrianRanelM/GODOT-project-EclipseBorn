extends Node2D

func _ready() -> void:
	if scene_manager.player:
		add_child(scene_manager.player)
