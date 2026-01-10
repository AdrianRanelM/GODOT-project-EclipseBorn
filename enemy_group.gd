extends Node2D

var enemies: Array = []
var action_queue: Array = []
var is_battling: bool = false
var index: int = 0

signal next_player

@onready var choice = $"../CanvasLayer/choice"
@onready var player_group = $"../PlayerGroup"

func _ready():
	# Initial positioning
	var children = get_children()
	for i in children.size():
		children[i].position = Vector2(0, i * 32)
	
	refresh_enemies()
	show_choice()

func refresh_enemies():
	# Only includes children who are not dead
	enemies = get_children().filter(func(node): return node.health > 0)

func _process(_delta):
	if not choice.visible and not is_battling:
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
			action_queue.push_back(enemies[index])
			emit_signal("next_player")

	if action_queue.size() == player_group.get_children().size() and not is_battling:
		is_battling = true
		_action(action_queue)
		_reset_focus()

func _action(stack):
	# PLAYER ATTACK PHASE
	for target in stack:
		if is_instance_valid(target) and target.health > 0:
			target.take_damage(1)
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
			# Get a living player to attack
			var living_players = player_group.get_children().filter(func(node): return node.health > 0)
			if living_players.size() > 0:
				enemy.attack(living_players.pick_random())
				await get_tree().create_timer(0.8).timeout

func switch_focus(x, y):
	if x < enemies.size(): enemies[x].focus()
	if y < enemies.size(): enemies[y].unfocus()

func show_choice():
	choice.show()
	choice.find_child("attack").grab_focus()

func _reset_focus():
	index = 0
	for enemy in get_children():
		enemy.unfocus()

func _start_choosing():
	refresh_enemies()
	_reset_focus()
	if enemies.size() > 0:
		enemies[0].focus()

func _on_attack_pressed():
	choice.hide()
	_start_choosing()
