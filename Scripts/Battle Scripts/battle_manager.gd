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
# Existing code & UI References
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
	visible = false

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
		var current_hp : float = float(hp_battle.value)
		if previous_hp >= 0.0 and current_hp + HP_DROP_THRESHOLD < previous_hp:
			_on_protagonist_hurt(previous_hp, current_hp)
		previous_hp = current_hp

func _connect_animation_finished_signals() -> void:
	if protagonist_sprite:
		var callable_sprite = Callable(self, "_on_sprite_animation_finished")
		if not protagonist_sprite.is_connected("animation_finished", callable_sprite):
			protagonist_sprite.connect("animation_finished", callable_sprite)
		return

	if protagonist and protagonist.has_node("AnimationPlayer"):
		var ap = protagonist.get_node("AnimationPlayer") as AnimationPlayer
		var callable_ap = Callable(self, "_on_animation_player_finished")
		if not ap.is_connected("animation_finished", callable_ap):
			ap.connect("animation_finished", callable_ap)
		return

	if fallback_sprite:
		var callable_fallback = Callable(self, "_on_sprite_animation_finished")
		if not fallback_sprite.is_connected("animation_finished", callable_fallback):
			fallback_sprite.connect("animation_finished", callable_fallback)

func _on_protagonist_hurt(old_hp: float, new_hp: float) -> void:
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite

	if anim_sprite:
		if anim_sprite.animation != "hurt":
			anim_sprite.play("hurt")

	if protagonist and protagonist.has_method("shake_sprite"):
		protagonist.call("shake_sprite")
	elif has_method("shake_sprite"):
		call_deferred("shake_sprite")

func _on_sprite_animation_finished() -> void:
	var anim_sprite: AnimatedSprite2D = protagonist_sprite if protagonist_sprite else fallback_sprite
	if not anim_sprite:
		return

	if protagonist and protagonist.has_method("is_dead") and protagonist.is_dead:
		return

	if anim_sprite.animation == "hurt":
		if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("idle"):
			anim_sprite.play("idle")

func _on_animation_player_finished(anim_name: String) -> void:
	if protagonist and protagonist.has_method("is_dead") and protagonist.is_dead:
		return

	if anim_name == "hurt":
		if protagonist and protagonist.has_node("AnimatedSprite2D"):
			var local_sprite = protagonist.get_node("AnimatedSprite2D") as AnimatedSprite2D
			if local_sprite and local_sprite.sprite_frames and local_sprite.sprite_frames.has_animation("idle"):
				local_sprite.play("idle")
				return

		if protagonist and protagonist.has_node("AnimationPlayer"):
			var ap = protagonist.get_node("AnimationPlayer") as AnimationPlayer
			if ap and ap.has_animation("idle"):
				ap.play("idle")
				return

		if fallback_sprite and fallback_sprite.sprite_frames and fallback_sprite.sprite_frames.has_animation("idle"):
			fallback_sprite.play("idle")

func death():
	if hp_battle.value == 0:
		fallback_sprite.play("death")
	else:
		fallback_sprite.play("idle")

func update_description(message: String):
	action_label.text = message
	action_label.visible_ratio = 0.0
	var tween = create_tween()
	var duration = message.length() * 0.03
	tween.tween_property(action_label, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	if action_label.text == message:
		action_label.text = ""

func resolve_turn(player_actions: Array):
	var enemy_actions = enemy_group.get_enemy_actions()
	
	await run_action_queue(player_actions)
	await run_action_queue(enemy_actions)
	
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
		if battle_music:
			battle_music.stop()
		if victory_fanfare:
			victory_fanfare.play()
			# Fixed timer closure here
			get_tree().create_timer(5.0).timeout.connect(func(): victory_fanfare.stop())

		await update_description("Victory! All enemies defeated.")
		end_battle(true)

func run_action_queue(queue):
	for action in queue:
		var attacker = action["attacker"]
		var target = action["target"]
		if is_instance_valid(attacker) and not attacker.is_dead:
			if is_instance_valid(target) and not target.is_dead:
				await _execute_move_logic(attacker, target, action["type"])
				await get_tree().create_timer(0.5).timeout

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
			attacker.mana -= 15
			var dmg = attacker.attack_damage * 2
			target.take_damage(dmg)
			target.show_floating_text(dmg, "damage")
			message = str(a_name) + " blasted " + str(t_name) + " with Fireball!"
			
		"double_strike":
			attacker.mana -= 20
			var strike_dmg = floor(attacker.attack_damage * 0.75)
			target.take_damage(strike_dmg)
			target.show_floating_text(strike_dmg, "damage")
			await get_tree().create_timer(0.2).timeout
			target.take_damage(strike_dmg)
			target.show_floating_text(strike_dmg, "damage")
			message = str(a_name) + " used Double Strike on " + str(t_name) + "!"

		"lifesteal":
			attacker.mana -= 30
			var damage_dealt = attacker.attack_damage * 1.5
			var heal_amount = floor(damage_dealt * 0.5)
			target.take_damage(damage_dealt)
			target.show_floating_text(damage_dealt, "damage")
			attacker.health += heal_amount
			attacker.show_floating_text(heal_amount, "heal")
			message = str(a_name) + " drained HP from " + str(t_name) + "!"
			
		"heal":
			attacker.mana -= 15
			target.health += 30
			target.show_floating_text(5, "heal")
			message = str(a_name) + " healed " + str(t_name) + "!"

	await update_description(message)

# ===============================
# Signal Connections
# ===============================

func _on_double_strike_button_pressed() -> void:
	var player = player_group.players[0]
	if player.mana >= 20:
		var action = {
			"attacker": player,
			"target": enemy_group.enemies[0],
			"type": "double_strike"
		}
		# Fixed function name here
		player_group.handle_player_action(action)
	else:
		update_description("Not enough mana!")

func _on_lifesteal_button_pressed() -> void:
	var player = player_group.players[0]
	if player.mana >= 30:
		var action = {
			"attacker": player,
			"target": enemy_group.enemies[0],
			"type": "lifesteal"
		}
		# Fixed function name here
		player_group.handle_player_action(action)
	else:
		update_description("Not enough mana!")

func _on_return_pressed() -> void:
	end_battle(false)
