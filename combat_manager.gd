extends Node

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup

func _ready() -> void:
	await get_tree().process_frame
	player_group.start_turn()

func _on_enemy_group_player_turn_ended() -> void:
	await enemy_group.enemy_turn(player_group.player)
	player_group.start_turn()
