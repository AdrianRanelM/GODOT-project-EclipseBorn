extends CharacterBody2D

@onready var _focus = $focus
@onready var progress_bar = $ProgressBar
@onready var animation_player = $AnimationPlayer

@export var MAX_HEALTH: float = 7
@export var attack_damage: int = 1

var is_dead: bool = false
var health: float = 7:
	set(value):
		health = value
		_update_progress_bar()
		_play_animation()

func _ready():
	_update_progress_bar()

func _update_progress_bar():
	progress_bar.value = (health / MAX_HEALTH) * 100

func _play_animation():
	animation_player.play("hurt")
	
func die():
	is_dead = true
	unfocus()
	# Optional: play death animation or fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	# Disables collisions so they are "untargetable" by physics/mouse
	set_process(false)

func focus():
	if not is_dead:
		_focus.show()

func unfocus():
	_focus.hide()

func take_damage(value):
	if is_dead: return
	health -= value

# ✅ SHARED ATTACK
func attack(target):
	if is_dead: return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
