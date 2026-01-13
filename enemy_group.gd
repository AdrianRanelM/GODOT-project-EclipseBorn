extends Node2D

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0

var selected_move_type: String = "attack"
var is_targeting_allies: bool = false

signal next_player

@onready var choice = $"../CanvasLayer/choice"
@onready var skill_container = $"../CanvasLayer/skill"
@onready var player_group = $"../PlayerGroup"

func _ready():
	# FIX 1: Only try to position actual CharacterBody2D nodes
	# This prevents the AnimationPlayer error seen in your screenshot
	var character_nodes = get_children().filter(func(node): return node is CharacterBody2D)
	
	for i in character_nodes.size():
		character_nodes[i].position = Vector2(0, i * 32)
	
	refresh_enemies()
	show_choice()

func refresh_enemies():
	# FIX 2: Only filter nodes that actually HAVE a health variable
	# This prevents the 'Invalid access to property health' error
	enemies = get_children().filter(func(node): 
		return node is CharacterBody2D and node.health > 0
	)

func _unhandled_input(event):
	if not choice.visible and not skill_container.visible and not is_battling:
		var targets = player_group.players if is_targeting_allies else enemies
		if targets.size() == 0: return

		if event.is_action_pressed("ui_up"):
			var old_index = index
			index = max(0, index - 1)
			_switch_target_focus(index, old_index, targets)
			get_viewport().set_input_as_handled()

		if event.is_action_pressed("ui_down"):
			var old_index = index
			index = min(targets.size() - 1, index + 1)
			_switch_target_focus(index, old_index, targets)
			get_viewport().set_input_as_handled()

		if event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_confirm_selection(targets)

func _confirm_selection(targets):
	var active_player = player_group.players[player_group.index]
	
	action_queue.push_back({
		"attacker": active_player,
		"target": targets[index],
		"type": selected_move_type
	})
	
	targets[index].unfocus()
	is_targeting_allies = false 
	selected_move_type = "attack"
	
	if action_queue.size() < player_group.get_children().filter(func(n): return n is CharacterBody2D).size():
		emit_signal("next_player")
		show_choice()
	else:
		_start_battle_phase()

func _start_battle_phase():
	is_battling = true
	_action(action_queue)
	_reset_focus()

func _switch_target_focus(new_idx, old_idx, list):
	if old_idx < list.size(): list[old_idx].unfocus()
	if new_idx < list.size(): list[new_idx].focus()

func _action(stack):
	for action in stack:
		var attacker = action["attacker"]
		var target = action["target"]
		var type = action["type"]
		
		if is_instance_valid(target) and is_instance_valid(attacker):
			match type:
				"fireball":
					attacker.mana -= 3
					target.take_damage(attacker.attack_damage * 3)
				"heal":
					attacker.mana -= 2
					target.health += 5
				"attack":
					attacker.attack(target)
			
			await get_tree().create_timer(1.0).timeout
	
	refresh_enemies()
	if enemies.size() <= 0:
		print("Victory!")
		return

	await _enemy_turn()
	action_queue.clear()
	is_battling = false
	show_choice()

func _enemy_turn():
	for enemy in enemies:
		var living_players = player_group.get_children().filter(func(node): return node is CharacterBody2D and node.health > 0)
		if living_players.size() > 0:
			enemy.attack(living_players.pick_random())
			await get_tree().create_timer(0.8).timeout

func show_choice():
	is_battling = false
	skill_container.hide()
	choice.show()
	var atk_btn = choice.find_child("attack")
	if atk_btn: atk_btn.grab_focus()

func _on_magic_pressed():
	choice.hide()
	skill_container.show()
	var fb_btn = skill_container.find_child("fireball")
	if fb_btn: fb_btn.grab_focus()

func _on_fireball_pressed():
	_prepare_targeting("fireball", false, 3)

func _on_heal_pressed():
	_prepare_targeting("heal", true, 2)

func _prepare_targeting(move_name: String, target_allies: bool, mana_cost: int):
	var active_player = player_group.players[player_group.index]
	if active_player.mana >= mana_cost:
		selected_move_type = move_name
		is_targeting_allies = target_allies
		skill_container.hide()
		choice.hide()
		
		# FIX 3: Safe focus release to prevent the crash in your screenshot
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner != null:
			focus_owner.release_focus()

		_start_choosing.call_deferred()
	else:
		print("Not enough mana!")

func _start_choosing():
	index = 0
	refresh_enemies()
	for e in get_children(): if e.has_method("unfocus"): e.unfocus()
	for p in player_group.players: if p.has_method("unfocus"): p.unfocus()
	
	if is_targeting_allies:
		player_group.players[0].focus()
	else:
		if enemies.size() > 0:
			enemies[0].focus()

func _on_attack_pressed():
	selected_move_type = "attack"
	is_targeting_allies = false
	choice.hide()
	skill_container.hide()
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner: focus_owner.release_focus()
	_start_choosing.call_deferred()

func _reset_focus():
	index = 0
	for enemy in get_children():
		if enemy.has_method("unfocus"): enemy.unfocus()

func _on_return_pressed():
	skill_container.hide()
	choice.show()
	var mag_btn = choice.find_child("magic")
	if mag_btn: mag_btn.grab_focus()
