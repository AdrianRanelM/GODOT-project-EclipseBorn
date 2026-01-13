extends Node2D

var enemies: Array = []

func _ready():
	# Ignore AnimationPlayers/Sprites when setting positions
	var character_nodes = get_children().filter(func(n): return n is CharacterBody2D)
	for i in character_nodes.size():
		character_nodes[i].position = Vector2(0, i * 32)
	refresh_enemies()

func refresh_enemies():
	# Only find nodes that are characters AND alive
	enemies = get_children().filter(func(node): 
		return node is CharacterBody2D and node.health > 0
	)

func get_enemy_actions() -> Array:
	var queue = []
	# Look up the living players from the sibling node
	var living_players = get_node("../PlayerGroup").players.filter(func(p): return not p.is_dead)
	
	for enemy in enemies:
		if living_players.size() > 0:
			queue.push_back({
				"attacker": enemy,
				"target": living_players.pick_random(),
				"type": "attack"
			})
	return queue
