extends Node2D

# ===============================
# Battle lifecycle
# ===============================
signal battle_finished(victory: bool)

@onready var battle_music = $BattleMusic
@onready var victory_fanfare = $VictoryFanfare

func start_battle() -> void:
	visible = true
	canvas_layer.visible = true
	if battle_music:
		battle_music.play()

func end_battle(victory: bool) -> void:
	visible = false
	canvas_layer.visible = false
	emit_signal("battle_finished", victory)

# ===============================
# UI & Node References
# ===============================
@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup
@onready var action_label = $CanvasLayer/ActionDescription
@onready var canvas_layer = $CanvasLayer

#--- Health and Mana UI ---
@onready var health_bar = $CanvasLayer/HealthPointsBar
@onready var mana_bar = $CanvasLayer/ManaPointsBar
@onready var hp_battle = $PlayerGroup/Sonny/ProgressBar
@onready var mp_battle = $PlayerGroup/Sonny/ManaBar

@onready var fallback_sprite: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D

var protagonist: Node = null
var protagonist_sprite: AnimatedSprite2D = null

var previous_hp: float = -1.0
const HP_DROP_THRESHOLD: float = 0.01

# ===============================
# Initialization & Process
# ===============================
func _ready() -> void:
	visible = false
	action_label.text = ""
	
	await get_tree().process_frame
	player_group.start_player_turn()

	if has_node("PlayerGroup/Sonny"):
		protagonist = get_node("PlayerGroup/Sonny")
		if protagonist.has_node("AnimatedSprite2D"):
			protagonist_sprite = protagonist.get_node("AnimatedSprite2D")

	_connect_animation_finished_signals()

	if hp_battle:
		previous_hp = float(hp_battle.value)
	else:
		previous_hp = 0.0

func _process(_delta: float) -> void:
	# 1. Update UI Bars
	if hp_battle and health_bar:
		health_bar.value = hp_battle.value
		health_bar.tooltip_text = str(hp_battle.value)
	if mp_battle and mana_bar:
		mana_bar.value = mp_battle.value
		mana_bar.tooltip_text = str(mp_battle.value)

	# 2. Monitor HP for Death or Hurt
	if hp_battle:
		var current_hp : float = float(hp_battle.value)
		
		# A. Check for Death FIRST (Critical priority)
		if current_hp <= 0:
			_handle_player_death()
			return # Stop processing so we don't trigger "hurt" logic
			
		# B. Check for Hurt (Only if not dead)
		if previous_hp >= 0.0 and current_hp + HP_DROP_THRESHOLD < previous_hp:
			_on_protagonist_hurt(previous_hp, current_hp)
		
		previous_hp = current_hp

# ===============================
# Animation Handling (The Smooth Fix)
# ===============================

# Helper to play animations on ANY node (Player or Enemy)
func _try_play_anim(node: Node, anim_name: String) -> void:
	if node.has_node("AnimatedSprite2D"):
		var sprite = node.get_node("AnimatedSprite2D")
		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
	elif node.has_node("AnimationPlayer"):
		var ap = node.get_node("AnimationPlayer")
		if ap.has_animation(anim_name):
			ap.play(anim_name)

# Connects the signal so we know when to go back to Idle
func _connect_animation_finished_signals() -> void:
	if protagonist_sprite:
		if not protagonist_sprite.animation_finished.is_connected(_on_sprite_animation_finished):
			protagonist_sprite.animation_finished.connect(_on_sprite_animation_finished)
	
	if fallback_sprite:
		if not fallback_sprite.animation_finished.is_connected(_on_sprite_animation_finished):
			fallback_sprite.animation_finished.connect(_on_sprite_animation_finished)

# Triggers the Hurt animation
func _on_protagonist_hurt(_old_hp: float, _new_hp: float) -> void:
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite
	
	if anim_sprite:
		# Don't interrupt death or existing hurt
		if anim_sprite.animation != "hurt" and anim_sprite.animation != "death":
			anim_sprite.play("hurt")
			if protagonist and protagonist.has_method("shake_sprite"):
				protagonist.shake_sprite()

# Triggers when ANY animation finishes
func _on_sprite_animation_finished() -> void:
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite
	if not anim_sprite:
		return

	# If we are dead, stay dead. Do not go to idle.
	if anim_sprite.animation == "death":
		return

	# If we finished Attacking, Casting, or Hurting -> Go back to IDLE
	var return_to_idle_anims = ["attack", "hurt", "fireball", "heal"]
	
	if anim_sprite.animation in return_to_idle_anims:
		if anim_sprite.sprite_frames.has_animation("idle"):
			anim_sprite.play("idle")

# ===============================
# Battle Logic & Turns
# ===============================

func resolve_turn(player_actions: Array):
	var enemy_actions = enemy_group.get_enemy_actions()
	
	await run_action_queue(player_actions)
	await run_action_queue(enemy_actions)
	
	# Regen Mana Phase
	for player in player_group.players:
		if is_instance_valid(player) and not player.is_dead:
			if player.mana < player.MAX_MANA:
				player.mana += 1
				if player.has_method("show_floating_text"):
					player.show_floating_text(1, "mana")

	enemy_group.refresh_enemies()
	if enemy_group.enemies.size() > 0:
		player_group.start_player_turn()
	else:
		_handle_victory()

func run_action_queue(queue):
	for action in queue:
		var attacker = action["attacker"]
		var target = action["target"]
		if is_instance_valid(attacker) and not attacker.is_dead:
			if is_instance_valid(target) and not target.is_dead:
				await _execute_move_logic(attacker, target, action["type"])
				# Small pause between turns for readability
				await get_tree().create_timer(0.5).timeout

func _execute_move_logic(attacker, target, type):
	var a_name = attacker.get("unit_name") if attacker.get("unit_name") else attacker.name
	var t_name = target.get("unit_name") if target.get("unit_name") else target.name
	var message = ""

	# 1. Play Attack Animation FIRST
	# (This waits for the animation to finish before showing damage numbers)
	if type == "attack":
		_try_play_anim(attacker, "attack")
		if attacker.has_node("AnimatedSprite2D"):
			await attacker.get_node("AnimatedSprite2D").animation_finished
		else:
			await get_tree().create_timer(0.5).timeout # Fallback wait
	elif type == "fireball":
		_try_play_anim(attacker, "fireball") # Assuming you have a 'fireball' anim
		await get_tree().create_timer(0.5).timeout

	# 2. Calculate & Apply Damage
	match type:
		"attack":
			attacker.attack(target)
			target.show_floating_text(attacker.attack_damage, "damage")
			message = str(a_name) + " attacked " + str(t_name) + "!"
		"fireball":
			attacker.mana -= 15
			var dmg = attacker.attack_damage * 2
			target.take_damage(dmg)
			target.show_floating_text(dmg, "damage")
			message = str(a_name) + " blasted " + str(t_name) + " with Fireball!"
		"double_strike":
			attacker.mana -= 20
			_try_play_anim(attacker, "attack") # Use standard attack anim for strike
			var strike_dmg = floor(attacker.attack_damage * 0.75)
			
			target.take_damage(strike_dmg)
			target.show_floating_text(strike_dmg, "damage")
			await get_tree().create_timer(0.2).timeout
			
			target.take_damage(strike_dmg)
			target.show_floating_text(strike_dmg, "damage")
			message = str(a_name) + " used Double Strike on " + str(t_name) + "!"
		"lifesteal":
			attacker.mana -= 30
			_try_play_anim(attacker, "attack")
			var damage_dealt = attacker.attack_damage * 1.5
			var heal_amount = floor(damage_dealt * 0.5)
			target.take_damage(damage_dealt)
			target.show_floating_text(damage_dealt, "damage")
			attacker.health += heal_amount
			attacker.show_floating_text(heal_amount, "heal")
			message = str(a_name) + " drained HP from " + str(t_name) + "!"
		"heal":
			attacker.mana -= 15
			_try_play_anim(attacker, "heal") # Assuming 'heal' anim exists
			target.health += 30
			target.show_floating_text(30, "heal")
			message = str(a_name) + " healed " + str(t_name) + "!"

	# 3. Update Text
	await update_description(message)

# ===============================
# End Game & Signals
# ===============================

func _handle_victory() -> void:
	if battle_music:
		battle_music.stop()
	if victory_fanfare:
		victory_fanfare.play()
		get_tree().create_timer(5.0).timeout.connect(func(): victory_fanfare.stop())

	await update_description("Victory! All enemies defeated.")
	end_battle(true)

func _handle_player_death() -> void:
	# Stop monitoring HP
	set_process(false)
	
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite
	
	if anim_sprite:
		if anim_sprite.sprite_frames.has_animation("death"):
			anim_sprite.play("death")
			# WAIT for the full death animation
			await anim_sprite.animation_finished
		else:
			await get_tree().create_timer(1.5).timeout

	if battle_music:
		battle_music.stop()

	get_tree().change_scene_to_file("res://Scenes/Mainmenu scenes/Game_Over.tscn")

func _on_double_strike_button_pressed() -> void:
	var player = player_group.players[0]
	if player.mana >= 20:
		player_group.handle_player_action({
			"attacker": player,
			"target": enemy_group.enemies[0],
			"type": "double_strike"
		})
	else:
		update_description("Not enough mana!")

func _on_lifesteal_button_pressed() -> void:
	var player = player_group.players[0]
	if player.mana >= 30:
		player_group.handle_player_action({
			"attacker": player,
			"target": enemy_group.enemies[0],
			"type": "lifesteal"
		})
	else:
		update_description("Not enough mana!")

func _on_return_pressed() -> void:
	end_battle(false)

func update_description(message: String):
	action_label.text = message
	action_label.visible_ratio = 0.0
	var tween = create_tween()
	var duration = max(0.5, message.length() * 0.03) # Minimum duration for readability
	tween.tween_property(action_label, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	# Wait a moment so player can read it before clearing
	await get_tree().create_timer(1.0).timeout
