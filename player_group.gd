extends Node2D

var players: Array = []
var index : int = 0

func _ready():
	players = get_children()
	for i in players.size():
		players[i].position = Vector2(0, i * 32)

func _on_enemy_group_next_player():
	index = (index + 1) % players.size()
	
	var safety = 0
	while players[index].health <= 0 and safety < players.size():
		index = (index + 1) % players.size()
		safety += 1
		
	# Unfocus everyone
	for p in players:
		p.unfocus()
