extends CharacterBody2D
class_name Enemy

# --- Enemy stats ---
@export var max_hp: int = 100
@export var damage: int = 10
@export var speed: float = 60.0

var current_hp: int
var target: Node = null   # player reference when detected

# --- Roaming ---
var roam_timer: float = 0.0
var roam_direction: Vector2 = Vector2.ZERO
@export var roam_interval: float = 2.0   # seconds before picking new direction

# --- References ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var battle_trigger: CollisionShape2D = $BattleTrigger

# --- Signals ---
signal enemy_died(enemy: Enemy)
signal enemy_damaged(enemy: Enemy, amount: int)

# --- Internal ---
var last_direction: Vector2 = Vector2.DOWN
var chase_axis: String = ""   # "x" or "y" to avoid jitter

func _ready() -> void:
	current_hp = max_hp
	if sprite and sprite.sprite_frames.has_animation("IdleDown"):
		sprite.play("IdleDown")

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if target:
		_chase_target()
	else:
		_roam(delta)

	move_and_slide()
	_update_animation()

# --- Chase logic without diagonal jitter ---
func _chase_target() -> void:
	var raw_dir = target.global_position - global_position

	# Decide axis once if not set
	if chase_axis == "":
		chase_axis = "x" if abs(raw_dir.x) > abs(raw_dir.y) else "y"

	# Move along chosen axis until close enough, then switch
	if chase_axis == "x":
		if abs(raw_dir.x) > 4:   # tolerance so it doesn’t flicker
			velocity = Vector2(sign(raw_dir.x), 0) * speed
		else:
			chase_axis = "y"
	else:
		if abs(raw_dir.y) > 4:
			velocity = Vector2(0, sign(raw_dir.y)) * speed
		else:
			chase_axis = "x"

# --- Roaming ---
func _roam(delta: float) -> void:
	chase_axis = ""   # reset when idle
	roam_timer -= delta
	if roam_timer <= 0:
		_pick_new_roam_direction()
		roam_timer = roam_interval
	velocity = roam_direction * speed

func _pick_new_roam_direction() -> void:
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]
	roam_direction = dirs[randi() % dirs.size()]

# --- Detection ---
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		target = body

func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null

# --- Animation handling ---
func _update_animation() -> void:
	if not sprite:
		return

	if velocity == Vector2.ZERO:
		if last_direction == Vector2.DOWN and sprite.sprite_frames.has_animation("IdleDown"):
			sprite.play("IdleDown")
		elif last_direction == Vector2.UP and sprite.sprite_frames.has_animation("IdleUp"):
			sprite.play("IdleUp")
		elif last_direction == Vector2.LEFT and sprite.sprite_frames.has_animation("IdleLeft"):
			sprite.play("IdleLeft")
		elif last_direction == Vector2.RIGHT and sprite.sprite_frames.has_animation("IdleRight"):
			sprite.play("IdleRight")
	else:
		if velocity.x > 0 and sprite.sprite_frames.has_animation("WalkRight"):
			sprite.play("WalkRight")
			last_direction = Vector2.RIGHT
		elif velocity.x < 0 and sprite.sprite_frames.has_animation("WalkLeft"):
			sprite.play("WalkLeft")
			last_direction = Vector2.LEFT
		elif velocity.y > 0 and sprite.sprite_frames.has_animation("WalkDown"):
			sprite.play("WalkDown")
			last_direction = Vector2.DOWN
		elif velocity.y < 0 and sprite.sprite_frames.has_animation("WalkUp"):
			sprite.play("WalkUp")
			last_direction = Vector2.UP

# --- Combat ---
#func _on_battle_trigger(body: Node) -> void:
	#if body.is_in_group("player"):
		## Initiate battle sequence
		#var battle_scene = preload("res://Battle.tscn")
		#get_tree().change_scene_to_packed(battle_scene)

func take_damage(amount: int) -> void:
	current_hp -= amount
	emit_signal("enemy_damaged", self, amount)
	if sprite and sprite.sprite_frames.has_animation("Hit"):
		sprite.play("Hit")
	if current_hp <= 0:
		die()

func die() -> void:
	emit_signal("enemy_died", self)
	if sprite and sprite.sprite_frames.has_animation("Death"):
		sprite.play("Death")
		await sprite.animation_finished
	queue_free()
