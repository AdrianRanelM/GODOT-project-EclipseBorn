extends Node

var player: CharacterBody2D

var scene_dir_path = "res://scenes/"

func change_scene(from, to_scene_name: String) -> void:
	if "player" in from:
		player = from.player
	
	if player != null and player.get_parent() != null:
		player.get_parent().remove_child(player)
	
	var full_path = scene_dir_path + to_scene_name + ".tscn"
	from.get_tree().call_deferred("change_scene_to_file", full_path)
