extends Node2D

var players: Array = []
var index: int = 0 
var target_index: int = 0 
var action_queue: Array = []

var is_selecting_target: bool = false
var current_move_type: String = ""
var targeting_allies: bool = false

@onready var choice_menu = $"../CanvasLayer/choice"
@onready var skill_menu = $"../CanvasLayer/skill"
@onready var enemy_group = $"../EnemyGroup"

func _ready():
	# Fill the array so it is not empty when show_menu runs
	players = get_children().filter(func(n): return n is CharacterBody2D)

func start_player_turn():
	index = 0
	action_queue = []
	is_selecting_target = false
	show_menu()

func show_menu():
	# If we exceed the player count, tell the manager to run the turn
	if index >= players.size():
		get_parent().resolve_turn(action_queue)
		return

	if players[index].is_dead:
		_advance_player()
		return
		
	choice_menu.show()
	skill_menu.hide()
	# Set focus on the first button for controller/keyboard support
	var atk_btn = choice_menu.find_child("attack")
	if atk_btn: atk_btn.grab_focus()

func _unhandled_input(event):
	if is_selecting_target:
		var targets = players if targeting_allies else enemy_group.enemies
		if targets.size() == 0: return

		if event.is_action_pressed("ui_up"):
			_change_target(-1, targets)
		elif event.is_action_pressed("ui_down"):
			_change_target(1, targets)
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_confirm_target(targets[target_index])

func _change_target(dir, targets):
	targets[target_index].unfocus()
	target_index = clampi(target_index + dir, 0, targets.size() - 1)
	targets[target_index].focus()

func _confirm_target(target):
	is_selecting_target = false
	target.unfocus()
	action_queue.push_back({
		"attacker": players[index], 
		"target": target, 
		"type": current_move_type
	})
	_advance_player()

func _advance_player():
	index += 1
	show_menu()

# --- Reconnect these button signals in the Editor! ---
func _on_attack_pressed(): _start_targeting("attack", false)
func _on_fireball_pressed(): _start_targeting("fireball", false)
func _on_heal_pressed(): _start_targeting("heal", true)

func _start_targeting(type, allies):
	current_move_type = type
	targeting_allies = allies
	choice_menu.hide()
	skill_menu.hide()
	
	# Release UI focus so "Enter" doesn't click the button again
	var focus_owner = get_viewport().gui_get_focus_owner()
	if focus_owner: focus_owner.release_focus()
	
	is_selecting_target = true
	target_index = 0
	var targets = players if targeting_allies else enemy_group.enemies
	if targets.size() > 0: targets[0].focus()


func _on_magic_pressed() -> void:
	# Hide the main "Attack/Magic/Run" menu
	choice_menu.hide()
	# Show the "Fireball/Heal/Return" menu
	skill_menu.show()
	# Focus the first skill button so keyboard/controller works
	var fireball_btn = skill_menu.find_child("fireball")
	if fireball_btn:
		fireball_btn.grab_focus()

func _on_return_pressed() -> void:
	# Hide the skill menu
	skill_menu.hide()
	# Show the main choice menu again
	choice_menu.show()
	# Refocus the "magic" button so the user is back where they started
	var magic_btn = choice_menu.find_child("magic")
	if magic_btn:
		magic_btn.grab_focus()
