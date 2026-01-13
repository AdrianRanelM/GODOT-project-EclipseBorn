extends CharacterBody2D

@onready var mana_bar = $ManaBar

@onready var _focus = $focus
@onready var progress_bar = $ProgressBar
@onready var animation_player = $AnimationPlayer

@export var MAX_HEALTH: float = 7
@export var attack_damage: int = 1

@export var MAX_MANA: float = 10


var mana: float = 10:
	set(value):
		mana = clamp(value, 0, MAX_MANA)
		_update_mana_bar()


var is_dead: bool = false

var health: float = 7:
	set(value):
		# clamp ensures health doesn't go below 0 or above MAX
		health = clamp(value, 0, MAX_HEALTH)
		_update_progress_bar()
		# Only play hurt animation if health actually went down
		if value < health:
			_play_animation()
		if health <= 0 and not is_dead:
			die()

func _ready():
	_update_progress_bar()
	_update_mana_bar()
	
func _update_progress_bar():
	progress_bar.value = (health / MAX_HEALTH) * 100

# Add this new function
func _update_mana_bar():
	if mana_bar:
		mana_bar.value = (mana / MAX_MANA) * 100

# Add a helper function to check if we can afford a spell
func use_mana(amount: int) -> bool:
	if mana >= amount:
		mana -= amount
		return true
	return false

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
