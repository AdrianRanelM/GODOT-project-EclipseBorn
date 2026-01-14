extends Node2D

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup
# Ensure ActionDescription is a Label inside your CanvasLayer
@onready var action_label = $CanvasLayer/ActionDescription

#---health and mana---
@onready var health_bar = $CanvasLayer/HealthPointsBar
@onready var mana_bar = $CanvasLayer/ManaPointsBar
@onready var hp_battle = $PlayerGroup/Sonny/ProgressBar
@onready var mp_battle = $PlayerGroup/Sonny/ManaBar

func _process(_delta):
	health_bar.value = hp_battle.value
	mana_bar.value   = mp_battle.value
	
	var hp_tooltip = str(hp_battle.value)
	var mp_tooltip = str(mp_battle.value)
	
	health_bar.tooltip_text = hp_tooltip
	mana_bar.tooltip_text = mp_tooltip

func _ready():
	action_label.text = "" # Clear it at the start
	await get_tree().process_frame
	player_group.start_player_turn()

# battle_manager.gd

func update_description(message: String):
	# Set the text and hide it immediately
	action_label.text = message
	action_label.visible_ratio = 0.0
	
	# Create a tween for the typewriter effect
	var tween = create_tween()
	
	# UPSCALE: We calculate speed based on message length (0.03s per character)
	var duration = message.length() * 0.03
	
	# Animate the visible_ratio from 0 to 1
	# FIX: Using TRANS_SINE to avoid "TRANS_OUT" errors seen in debugger
	tween.tween_property(action_label, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_SINE)
	
	# Wait for the typing to finish before clearing or moving on
	await tween.finished
	
	# Wait an extra 1 second for the player to read
	await get_tree().create_timer(1.0).timeout

	# Clear if it hasn't been changed by a new message
	if action_label.text == message:
		action_label.text = ""

func resolve_turn(player_actions: Array):
	# 1. Gather enemy actions
	var enemy_actions = enemy_group.get_enemy_actions()
	
	# 2. Run sequences
	await run_action_queue(player_actions)
	await run_action_queue(enemy_actions)
	
	# 3. Mana Regen Phase
	for player in player_group.players:
		if is_instance_valid(player) and not player.is_dead:
			if player.mana < player.MAX_MANA:
				player.mana += 1
				if player.has_method("show_floating_text"):
					# FIX: Pass "mana" String to avoid bool-to-string conversion error
					player.show_floating_text(1, "mana") 

	# 4. Victory Check
	enemy_group.refresh_enemies()
	if enemy_group.enemies.size() > 0:
		player_group.start_player_turn()
	else:
		update_description("Victory! All enemies defeated.")
		print("Victory!")

func run_action_queue(queue):
	for action in queue:
		var attacker = action["attacker"]
		var target = action["target"]
		if is_instance_valid(attacker) and not attacker.is_dead:
			if is_instance_valid(target) and not target.is_dead:
				_execute_move_logic(attacker, target, action["type"])
				# Pause for 1.5 seconds so the player can read the description
				await get_tree().create_timer(1.5).timeout

func _execute_move_logic(attacker, target, type):
	var a_name = attacker.get("unit_name") if attacker.get("unit_name") else attacker.name
	var t_name = target.get("unit_name") if target.get("unit_name") else target.name
	var message = ""

	match type:
		"attack":
			attacker.attack(target)
			target.show_floating_text(attacker.attack_damage, "damage")
			message = str(a_name) + " attacked " + str(t_name) + "!"
		"fireball":
			attacker.mana -= 3
			var dmg = attacker.attack_damage * 3
			target.take_damage(dmg)
			target.show_floating_text(dmg, "damage")
			message = str(a_name) + " blasted " + str(t_name) + " with Fireball!"
		"heal":
			attacker.mana -= 2
			target.health += 5
			target.show_floating_text(5, "heal") # FIX: String "heal"
			message = str(a_name) + " healed " + str(t_name) + "!"

	# CRITICAL: Use 'await' so the turn manager waits for the typing to end
	await update_description(message)
