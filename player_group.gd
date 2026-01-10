extends Node2D

var players: Array = []
var index : int = 0

func _ready():
	players = get_children()
	for i in players.size():
		players[i].position = Vector2(0, i * 32)

func _on_enemy_group_next_player():
	# Advance index and wrap around
	var old_index = index
	index = (index + 1) % players.size()
	
	# Skip dead players
	var safety_check = 0
	while players[index].health <= 0 and safety_check < players.size():
		index = (index + 1) % players.size()
		safety_check += 1
		
	switch_focus(index, old_index)

func switch_focus(x, y):
	if x < players.size(): players[x].focus()
	if x != y and y < players.size(): players[y].unfocus()

# This allows the enemy group to call take_damage on the group 
# if you haven't specified a single player target
func take_damage(amount: int):
	var living_players = get_children().filter(func(node): return node.health > 0)
	if living_players.size() > 0:
		living_players.pick_random().take_damage(amount)
