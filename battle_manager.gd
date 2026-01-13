
extends Node2D

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup

func _ready():
	# Wait for children to finish their _ready calls
	await get_tree().process_frame
	player_group.start_player_turn()

# This is called by PlayerGroup once all players have picked their moves
func resolve_turn(player_actions: Array):
	# 1. FIX: Declare enemy_actions before using it
	var enemy_actions = enemy_group.get_enemy_actions()
	
	# 2. Run sequences
	await run_action_queue(player_actions)
	await run_action_queue(enemy_actions)
	
	# 3. MANA REGEN PHASE
	for player in player_group.players:
		if is_instance_valid(player) and not player.is_dead:
			if player.mana < player.MAX_MANA:
				player.mana += 1
				if player.has_method("show_floating_text"):
					# FIX: Change 'true' to "mana" to match the String argument
					player.show_floating_text(1, "mana") 

	# 4. Victory Check
	enemy_group.refresh_enemies()
	if enemy_group.enemies.size() > 0:
		player_group.start_player_turn()
	else:
		print("Victory! All enemies defeated.")

func run_action_queue(queue):
	for action in queue:
		var attacker = action["attacker"]
		var target = action["target"]
		
		# Ensure both are still valid and alive before acting
		if is_instance_valid(attacker) and not attacker.is_dead:
			if is_instance_valid(target) and not target.is_dead:
				_execute_move_logic(attacker, target, action["type"])
				# Pause for the "floating text" and shake to be seen
				await get_tree().create_timer(1.0).timeout

func _execute_move_logic(attacker, target, type):
	match type:
		"attack":
			attacker.attack(target)
			target.show_floating_text(attacker.attack_damage)
		"fireball":
			attacker.mana -= 3
			var dmg = attacker.attack_damage * 3
			target.take_damage(dmg)
			target.show_floating_text(dmg)
		"heal":
			attacker.mana -= 2
			target.health += 5
			target.show_floating_text(5, "heal")
