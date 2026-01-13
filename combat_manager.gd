extends Node2D

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup

func _ready():
	await get_tree().process_frame
	player_group.start_player_turn()

func resolve_turn(player_actions: Array):
	# 1. Gather enemy actions - FIX: Properly declared before use
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
					# FIX: Pass "mana" String to match the new character script
					player.show_floating_text(1, "mana") 

	# 4. Victory Check
	enemy_group.refresh_enemies()
	if enemy_group.enemies.size() > 0:
		player_group.start_player_turn()
	else:
		print("Victory!")

func run_action_queue(queue):
	for action in queue:
		var attacker = action["attacker"]
		var target = action["target"]
		if is_instance_valid(attacker) and not attacker.is_dead:
			if is_instance_valid(target) and not target.is_dead:
				_execute_move_logic(attacker, target, action["type"])
				await get_tree().create_timer(1.0).timeout

func _execute_move_logic(attacker, target, type):
	match type:
		"attack":
			attacker.attack(target)
			target.show_floating_text(attacker.attack_damage, "damage")
		"fireball":
			attacker.mana -= 3
			var fireball_dmg = attacker.attack_damage * 3
			target.take_damage(fireball_dmg)
			# FIX: Pass "damage" String
			target.show_floating_text(fireball_dmg, "damage")
		"heal":
			attacker.mana -= 2
			target.health += 5
			# FIX: Pass "heal" String (used to be 'true')
			target.show_floating_text(5, "heal")
