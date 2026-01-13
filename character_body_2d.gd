extends CharacterBody2D

@onready var _focus = $focus
@onready var progress_bar = $ProgressBar
@onready var mana_bar = $ManaBar 
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D 

@export var MAX_HEALTH: float = 7
@export var MAX_MANA: float = 10
@export var attack_damage: int = 1

var floating_text_scene = preload("res://FloatingText.tscn")
var is_dead: bool = false
var pulse_tween: Tween
var bounce_tween: Tween

var health: float = 7:
	set(value):
		var old_health = health
		health = clamp(value, 0, MAX_HEALTH)
		_update_progress_bar()
		if health < old_health:
			_play_animation()
			shake_sprite()
		if health <= 0 and not is_dead:
			die()

var mana: float = 10:
	set(value):
		mana = clamp(value, 0, MAX_MANA)
		_update_mana_bar()

func _ready():
	_update_progress_bar()
	_update_mana_bar()

func _update_progress_bar():
	if progress_bar: progress_bar.value = (health / MAX_HEALTH) * 100

func _update_mana_bar():
	if mana_bar: mana_bar.value = (mana / MAX_MANA) * 100

func take_damage(value):
	if is_dead: return
	health -= value

func attack(target):
	if is_dead: return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

# --- Visuals & Animations ---

func show_floating_text(amount: int, type: String = "damage"):
	var text_instance = floating_text_scene.instantiate()
	text_instance.position = Vector2(-20, -50) 
	
	var text_color = Color.RED
	var text_prefix = "-"
	
	match type:
		"heal":
			text_color = Color.GREEN
			text_prefix = "+"
		"mana":
			text_color = Color.CYAN # Blue for Mana
			text_prefix = "+"
		"damage":
			text_color = Color.RED
			text_prefix = "-"

	text_instance.setup(text_prefix + str(amount), text_color)
	add_child(text_instance)

func focus():
	if not is_dead:
		_focus.show()
		_start_pulse_animation()
		_start_bounce_animation()

func unfocus():
	_focus.hide()
	_stop_animations()

func _start_pulse_animation():
	if pulse_tween: pulse_tween.kill()
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(sprite, "modulate", Color(1.8, 1.8, 1.8), 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.6).set_trans(Tween.TRANS_SINE)

func _start_bounce_animation():
	if bounce_tween: bounce_tween.kill()
	bounce_tween = create_tween().set_loops()
	var start_y = _focus.position.y
	bounce_tween.tween_property(_focus, "position:y", start_y - 10, 0.4).set_trans(Tween.TRANS_SINE)
	bounce_tween.tween_property(_focus, "position:y", start_y, 0.4).set_trans(Tween.TRANS_SINE)

func _stop_animations():
	if pulse_tween: pulse_tween.kill()
	if bounce_tween: bounce_tween.kill()
	sprite.modulate = Color(1, 1, 1)

func shake_sprite():
	var original_pos = sprite.position
	var shake_tween = create_tween()
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(4, 0), 0.05)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(-4, 0), 0.05)
	shake_tween.tween_property(sprite, "position", original_pos, 0.05)

func _play_animation():
	if animation_player.has_animation("hurt"):
		animation_player.stop()
		animation_player.play("hurt")

func die():
	is_dead = true
	unfocus()
	var death_tween = create_tween()
	death_tween.tween_property(self, "modulate:a", 0.0, 0.5)
