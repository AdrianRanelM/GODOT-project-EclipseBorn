extends Node2D

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0

# Track what kind of move is being queued
var selected_move_type: String = "attack"

signal next_player

@onready var choice = $"../CanvasLayer/choice"
@onready var skill_container = $"../CanvasLayer/skill"
@onready var player_group = $"../PlayerGroup"

func _ready():
	# Initial positioning of enemies
	var children = get_children()
	for i in children.size():
		children[i].position = Vector2(0, i * 32)
	
	refresh_enemies()
	show_choice()

func refresh_enemies():
	# Only includes children who are not dead
	enemies = get_children().filter(func(node): return node.health > 0)

func _process(_delta):
	# Selection logic only runs if UI is hidden and we aren't currently animating a battle
	if not choice.visible and not skill_container.visible and not is_battling:
		if enemies.size() == 0: return

		if Input.is_action_just_pressed("ui_up"):
			if index > 0:
				index -= 1
				switch_focus(index, index + 1)

		if Input.is_action_just_pressed("ui_down"):
			if index < enemies.size() - 1:
				index += 1
				switch_focus(index, index - 1)

		if Input.is_action_just_pressed("ui_accept"):
			# Store the Node itself so we hit the right target even if indices change
			var active_player = player_group.players[player_group.index]
			
			action_queue.push_back({
				"attacker": active_player,
				"target": enemies[index],
				"type": selected_move_type
			})
			
			# Reset move type for next player selection
			selected_move_type = "attack"
			emit_signal("next_player")

	# Check if all players have chosen an action
	if action_queue.size() == player_group.get_children().size() and not is_battling:
		is_battling = true
		_action(action_queue)
		_reset_focus()

func _action(stack):
	# PLAYER ATTACK PHASE
	for action in stack:
		var attacker = action["attacker"]
		var target = action["target"]
		var type = action["type"]
		
		if is_instance_valid(target) and target.health > 0 and is_instance_valid(attacker):
			if type == "fireball":
				# Deduct mana if the character has the mana variable
				attacker.mana -= 3 
				target.take_damage(attacker.attack_damage * 3)
				print("Fireball cast!")
			else:
				attacker.attack(target)
			
			await get_tree().create_timer(1).timeout
	
	refresh_enemies()
	
	# Check if battle ended
	if enemies.size() <= 0:
		print("Victory!")
		return

	# ENEMY ATTACK PHASE
	await _enemy_turn()

	action_queue.clear()
	is_battling = false
	refresh_enemies()
	show_choice()

func _enemy_turn():
	for enemy in enemies:
		if enemy.health > 0:
			var living_players = player_group.get_children().filter(func(node): return node.health > 0)
			if living_players.size() > 0:
				enemy.attack(living_players.pick_random())
				await get_tree().create_timer(0.8).timeout

func switch_focus(x, y):
	if x < enemies.size(): enemies[x].focus()
	if y < enemies.size(): enemies[y].unfocus()

func show_choice():
	skill_container.hide()
	choice.show()
	# Ensure the button name in find_child matches your Scene Tree exactly
	var attack_btn = choice.find_child("attack")
	if attack_btn:
		attack_btn.grab_focus()
	
func _on_magic_pressed():
	choice.hide()
	skill_container.show()
	var fireball_btn = skill_container.find_child("fireball")
	if fireball_btn:
		fireball_btn.grab_focus()

func _on_back_pressed():
	skill_container.hide()
	choice.show()
	var magic_btn = choice.find_child("magic")
	if magic_btn:
		magic_btn.grab_focus()

func _on_fireball_pressed():
	var active_player = player_group.players[player_group.index]
	if active_player.mana >= 3:
		selected_move_type = "fireball"
		
		# Hide the UI menus
		skill_container.hide()
		choice.hide()
		
		# Clear UI focus so it doesn't block keyboard input
		var current_focus = get_viewport().gui_get_focus_owner()
		if current_focus:
			current_focus.release_focus()

		# IMPORTANT: Wait for the frame to end so the 'Enter' key 
		# doesn't trigger the enemy selection immediately
		await get_tree().process_frame

		_start_choosing()
	else:
		print("Not enough mana!")

func _reset_focus():
	index = 0
	for enemy in get_children():
		enemy.unfocus()

func _start_choosing():
	print("Targeting mode started!")
	refresh_enemies()
	_reset_focus()
	if enemies.size() > 0:
		enemies[0].focus()
		print("Focused on enemy 0")	

func _on_attack_pressed():
	selected_move_type = "attack"
	choice.hide()
	_start_choosing()

# This connects to your "Return" or "Cancel" button in the skill menu
func _on_return_pressed():
	_on_back_pressed()
