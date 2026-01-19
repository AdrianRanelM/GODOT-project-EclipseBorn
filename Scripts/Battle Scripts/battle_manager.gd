extends Node2D

# ===============================
# Battle lifecycle (ADDED)
# ===============================
signal battle_finished(victory: bool)

func start_battle() -> void:
	visible = true
	canvas_layer.visible = true
 
func end_battle(victory: bool) -> void:
	visible = false
	canvas_layer.visible = false
	emit_signal("battle_finished", victory)

# ===============================
# Existing code
# ===============================

@onready var player_group = $PlayerGroup
@onready var enemy_group = $EnemyGroup
@onready var action_label = $CanvasLayer/ActionDescription
@onready var canvas_layer = $CanvasLayer

#---health and mana---
@onready var health_bar = $CanvasLayer/HealthPointsBar
@onready var mana_bar = $CanvasLayer/ManaPointsBar
@onready var hp_battle = $PlayerGroup/Sonny/ProgressBar
@onready var mp_battle = $PlayerGroup/Sonny/ManaBar

@onready var fallback_sprite: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D

var protagonist: Node = null
var protagonist_sprite: AnimatedSprite2D = null

var previous_hp: float = -1.0
const HP_DROP_THRESHOLD: float = 0.01

func _ready() -> void:
	visible = false # IMPORTANT: start hidden

	action_label.text = ""
	await get_tree().process_frame
	player_group.start_player_turn()

	if has_node("PlayerGroup/Sonny"):
		protagonist = get_node("PlayerGroup/Sonny")
		if protagonist.has_node("AnimatedSprite2D"):
			protagonist_sprite = protagonist.get_node("AnimatedSprite2D")
	else:
		protagonist = null
		protagonist_sprite = null

	_connect_animation_finished_signals()

	if hp_battle:
		previous_hp = float(hp_battle.value)
	else:
		previous_hp = 0.0

func _process(_delta: float) -> void:
	if hp_battle and health_bar:
		health_bar.value = hp_battle.value
		health_bar.tooltip_text = str(hp_battle.value)
	if mp_battle and mana_bar:
		mana_bar.value = mp_battle.value
		mana_bar.tooltip_text = str(mp_battle.value)

	if hp_battle:
		var current_hp := float(hp_battle.value)
		if previous_hp >= 0.0 and current_hp + HP_DROP_THRESHOLD < previous_hp:
			_on_protagonist_hurt(previous_hp, current_hp)
		previous_hp = current_hp

# --- helper to connect signals safely ---
func _connect_animation_finished_signals() -> void:
	# If protagonist has AnimatedSprite2D, connect its signal
	if protagonist_sprite:
		var callable_sprite = Callable(self, "_on_sprite_animation_finished")
		if not protagonist_sprite.is_connected("animation_finished", callable_sprite):
			protagonist_sprite.connect("animation_finished", callable_sprite)
		return

	# If protagonist uses AnimationPlayer instead, connect that (AnimationPlayer passes the animation name)
	if protagonist and protagonist.has_node("AnimationPlayer"):
		var ap = protagonist.get_node("AnimationPlayer") as AnimationPlayer
		var callable_ap = Callable(self, "_on_animation_player_finished")
		if not ap.is_connected("animation_finished", callable_ap):
			ap.connect("animation_finished", callable_ap)
		return

	# Fallback: connect the global/fallback AnimatedSprite2D if present
	if fallback_sprite:
		var callable_fallback = Callable(self, "_on_sprite_animation_finished")
		if not fallback_sprite.is_connected("animation_finished", callable_fallback):
			fallback_sprite.connect("animation_finished", callable_fallback)

# Called when protagonist HP drops
func _on_protagonist_hurt(old_hp: float, new_hp: float) -> void:
	# Choose the sprite to play the animation on: protagonist-local if available, else fallback
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite

	if anim_sprite:
		# Avoid restarting the hurt animation if it's already playing
		if anim_sprite.animation != "hurt":
			anim_sprite.play("hurt")

	# Optional: call a shake function if the protagonist has one or use fallback
	if protagonist and protagonist.has_method("shake_sprite"):
		protagonist.call("shake_sprite")
	elif has_method("shake_sprite"):
		call_deferred("shake_sprite")

# --- AnimatedSprite2D signal handler (no args) ---
func _on_sprite_animation_finished() -> void:
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite
	if not anim_sprite:
		return

	# If protagonist is dead, don't switch back to idle
	if protagonist and protagonist.has_method("is_dead") and protagonist.is_dead:
		return

	# If the finished animation was "hurt", return to "idle"
	if anim_sprite.animation == "hurt":
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("idle"):
			anim_sprite.play("idle")

# --- AnimationPlayer signal handler (passes animation name) ---
func _on_animation_player_finished(anim_name: String) -> void:
	# If protagonist is dead, don't switch back to idle
	if protagonist and protagonist.has_method("is_dead") and protagonist.is_dead:
		return

	# Only react to the hurt animation finishing
	if anim_name == "hurt":
		# If protagonist has an AnimatedSprite2D idle, prefer that
		if protagonist and protagonist.has_node("AnimatedSprite2D"):
			var local_sprite = protagonist.get_node("AnimatedSprite2D") as AnimatedSprite2D
			if local_sprite and local_sprite.sprite_frames and local_sprite.sprite_frames.has_animation("idle"):
				local_sprite.play("idle")
				return

		# Otherwise, try to play idle on the AnimationPlayer itself
		if protagonist and protagonist.has_node("AnimationPlayer"):
			var ap = protagonist.get_node("AnimationPlayer") as AnimationPlayer
			if ap and ap.has_animation("idle"):
				ap.play("idle")
				return

		# Fallback to global sprite
		if fallback_sprite and fallback_sprite.sprite_frames and fallback_sprite.sprite_frames.has_animation("idle"):
			fallback_sprite.play("idle")

func death():
	if hp_battle.value == 0:
		fallback_sprite.play("death")
	else:
		fallback_sprite.play("idle")	

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
