extends CharacterBody2D



@onready var _focus = $focus
@onready var progress_bar = $ProgressBar
@onready var mana_bar = $ManaBar 
@onready var animation_player = $AnimationPlayer

@export var MAX_HEALTH: float = 7
@export var MAX_MANA: float = 10
@export var attack_damage: int = 1

var floating_text_scene = preload("res://FloatingText.tscn")

func show_floating_text(amount: int, is_heal: bool = false):
	var text_instance = floating_text_scene.instantiate()
	
	# Position it slightly above the character
	text_instance.position = Vector2(-20, -50) 
	
	if is_heal:
		text_instance.setup("+" + str(amount), Color.GREEN)
	else:
		text_instance.setup("-" + str(amount), Color.RED)
		
	add_child(text_instance)



var is_dead: bool = false
var health: float = 7:
	set(value):
		var old_health = health
		health = clamp(value, 0, MAX_HEALTH)
		_update_progress_bar()
		if health < old_health:
			_play_animation()
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

func _play_animation():
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")
	
func die():
	is_dead = true
	unfocus()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	set_process(false)

func focus():
	if not is_dead:
		print(name, " is now focused!") # Add this to confirm the function runs
		_focus.show()

func unfocus():
	_focus.hide()

func take_damage(value):
	if is_dead: return
	health -= value

func attack(target):
	if is_dead: return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
