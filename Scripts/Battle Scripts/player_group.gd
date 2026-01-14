extends Node2D

var players: Array = []
var index: int = 0 
var target_index: int = 0 
var action_queue: Array = []

var is_selecting_target: bool = false
var current_move_type: String = ""
var targeting_allies: bool = false

# Dictionary to manage skill costs in one place
var move_costs = {
	"attack": 0,
	"fireball": 3,
	"heal": 2
}

@onready var choice_menu = $"../CanvasLayer/choice"
@onready var skill_menu = $"../CanvasLayer/skill"
@onready var enemy_group = $"../EnemyGroup"

func _ready():
	# Fill the array with living players
	players = get_children().filter(func(n): return n is CharacterBody2D)
	print("Choice menu:", choice_menu)
	print("Skill menu:", skill_menu)
	print("Enemy group:", enemy_group)

func start_player_turn():
	index = 0
	action_queue = []
	is_selecting_target = false
	show_menu()

func show_menu():
	# SAFETY: If everyone is dead, stop the loop to prevent recursion crashes
	var living_players = players.filter(func(p): return not p.is_dead)
	if living_players.size() == 0:
		print("Game Over: All players are dead.")
		return
		
	# If all players have picked their moves, send queue to the Battle Manager
	if index >= players.size():
		get_parent().resolve_turn(action_queue)
		return

	# If the current player is dead, skip to the next one
	if players[index].is_dead:
		_advance_player()
		return
		
	# Setup the UI
	choice_menu.show()
	skill_menu.hide()
	
	# Set focus for controller/keyboard support
	var atk_btn = choice_menu.find_child("attack")
	if atk_btn: 
		atk_btn.grab_focus()

func _unhandled_input(event):
	if is_selecting_target:
		var targets = players if targeting_allies else enemy_group.enemies
		if targets.size() == 0: return

		if event.is_action_pressed("ui_left"):
			_change_target(-1, targets)
		elif event.is_action_pressed("ui_right"):
			_change_target(1, targets)
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_confirm_target(targets[target_index])
		# --- Cancel Logic ---
		elif event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_cancel_targeting(targets)

func _change_target(dir, targets):
	targets[target_index].unfocus() #
	# Wrap around the index or clamp it
	target_index = clampi(target_index + dir, 0, targets.size() - 1)
	targets[target_index].focus()

func _confirm_target(target):
	is_selecting_target = false
	target.unfocus()
	
	# Add the action to the queue
	action_queue.push_back({
		"attacker": players[index], 
		"target": target, 
		"type": current_move_type
	})
	
	_advance_player()

# --- Function to handle exiting targeting mode ---
func _cancel_targeting(targets):
	is_selecting_target = false
	
	# Stop animations on the current target
	if targets.size() > 0:
		targets[target_index].unfocus()
	
	# Go back to the correct menu based on what action was being picked
	if current_move_type == "attack":
		choice_menu.show()
		var atk_btn = choice_menu.find_child("attack")
		if atk_btn: atk_btn.grab_focus()
	else:
		# Returns to magic menu for fireball/heal
		skill_menu.show()
		var skill_btn = skill_menu.find_child(current_move_type)
		if skill_btn and not skill_btn.disabled:
			skill_btn.grab_focus()
		else:
			skill_menu.find_child("return").grab_focus()

func _advance_player():
	index += 1
	# Using call_deferred prevents the "Stack Overflow" error
	show_menu.call_deferred()

# --- Button Signal Handlers ---

func _on_attack_pressed():
	print("done")
	_start_targeting("attack", false)

func _on_fireball_pressed():
	_start_targeting("fireball", false)

func _on_heal_pressed():
	var active_player = players[index]
	# PREVENT HEAL IF AT FULL HP: Checks if player needs healing before targeting
	if active_player.health >= active_player.MAX_HEALTH:
		print("Player is already at full health!")
		return
		
	_start_targeting("heal", true)

func _on_magic_pressed() -> void:
	choice_menu.hide()
	skill_menu.show()
	
	var active_player = players[index]
	
	# Visual Mana Check: Disable buttons if player can't afford the spell
	var fireball_btn = skill_menu.find_child("fireball")
	var heal_btn = skill_menu.find_child("heal")
	
	if fireball_btn:
		fireball_btn.disabled = active_player.mana < move_costs["fireball"]
	
	if heal_btn:
		# Disable if not enough mana OR if already at max health
		var out_of_mana = active_player.mana < move_costs["heal"]
		var health_full = active_player.health >= active_player.MAX_HEALTH
		heal_btn.disabled = out_of_mana or health_full
		
	# Focus logic: grab first available skill or the return button
	if fireball_btn and not fireball_btn.disabled:
		fireball_btn.grab_focus()
	elif heal_btn and not heal_btn.disabled:
		heal_btn.grab_focus()
	else:
		var ret_btn = skill_menu.find_child("return")
		if ret_btn: ret_btn.grab_focus()

func _on_return_pressed() -> void:
	skill_menu.hide()
	choice_menu.show()
	var magic_btn = choice_menu.find_child("magic")
	if magic_btn:
		magic_btn.grab_focus()

# --- Internal Logic ---

func _start_targeting(type, allies):
	var active_player = players[index]
	var cost = move_costs.get(type, 0)
	
	# Functional Mana Check
	if active_player.mana < cost:
		print("NOT ENOUGH MANA! Needs: ", cost, " Has: ", active_player.mana)
		return 
	
	current_move_type = type
	targeting_allies = allies
	
	# Hide menus so the player can see the targets
	choice_menu.hide()
	skill_menu.hide()
	
	# Release UI focus so "Enter/Space" doesn't re-trigger a button
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner: 
		focus_owner.release_focus()
	
	is_selecting_target = true
	target_index = 0
	
	# Start targeting indicator
	var targets = players if targeting_allies else enemy_group.enemies
	if targets.size() > 0: 
		targets[0].focus()

@onready var inventory_ui = $"../CanvasLayer/InventoryUI"
#--item usage by inventory--
func _on_items_pressed() -> void:
	inventory_ui.show()

func _on_inv_ui_back_pressed() -> void:
	inventory_ui.hide() # Replace with function body.
