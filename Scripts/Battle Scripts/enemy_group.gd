extends Node2D

var enemies: Array = []

func _ready():
	# Ignore AnimationPlayers/Sprites when setting positions
	var character_nodes = get_children().filter(func(n): return n is CharacterBody2D)
	
	var spacing = 350 # Change this value to adjust the gap between enemies
	
	for i in character_nodes.size():
		# FIX: Multiply the index 'i' by 'spacing' on the X axis (the first number)
		# Keep Y at 0 (the second number) so they all stay at the same height
		character_nodes[i].position = Vector2(i * spacing, 0)
	
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
