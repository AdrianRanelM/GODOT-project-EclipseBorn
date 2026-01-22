extends CharacterBody2D
class_name EnemyBase

# --- Overridable Stats ---
@export var max_hp: int = 100
@export var damage: int = 10
@export var roam_speed: float = 20.0
@export var chase_speed: float = 70.0

# This allows you to pick a different .tscn for every enemy in the Inspector
@export_file("*.tscn") var battle_scene_file: String = "res://Scenes/Battle scenes/battle_scene.tscn"

var current_hp: int
var target: Node = null
var last_direction: Vector2 = Vector2.DOWN
var chase_axis: String = ""
var roam_timer: float = 0.0
var roam_direction: Vector2 = Vector2.ZERO
@export var roam_interval: float = 2.0

# --- References ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D
@onready var battle_trigger: Area2D = $BattleTriggerArea

# --- Signals ---
signal enemy_died(enemy: EnemyBase)

func _ready() -> void:
	_setup_enemy()
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	battle_trigger.body_entered.connect(_on_battle_trigger)

# Helper for child scripts to override
func _setup_enemy() -> void:
	current_hp = max_hp

func _physics_process(delta: float) -> void:
	z_index = int(global_position.y)
	if target:
		_chase_target()
	else:
		_roam(delta)
	move_and_slide()
	_update_animation()

# --- Movement Logic ---
func _chase_target() -> void:
	if not target: return
	var raw_dir = target.global_position - global_position
	if chase_axis == "" or abs(velocity.length()) < 1:
		chase_axis = "x" if abs(raw_dir.x) > abs(raw_dir.y) else "y"

	if chase_axis == "x":
		velocity = Vector2(sign(raw_dir.x), 0) * chase_speed if abs(raw_dir.x) > 4 else Vector2.ZERO
		if abs(raw_dir.x) <= 4: chase_axis = "y"
	else:
		velocity = Vector2(0, sign(raw_dir.y)) * chase_speed if abs(raw_dir.y) > 4 else Vector2.ZERO
		if abs(raw_dir.y) <= 4: chase_axis = "x"

func _roam(delta: float) -> void:
	chase_axis = ""
	roam_timer -= delta
	if roam_timer <= 0:
		var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]
		roam_direction = dirs.pick_random()
		print("New roam direction: ", roam_direction) # DEBUG LINE
		roam_timer = roam_interval
	velocity = roam_direction * roam_speed

# --- Detection ---
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"): target = body

func _on_body_exited(body: Node) -> void:
	if body == target: target = null

# --- Animation ---
func _update_animation() -> void:
	if not sprite: return
	if velocity == Vector2.ZERO:
		_play_anim("Idle")
	else:
		if abs(velocity.x) > abs(velocity.y):
			last_direction = Vector2.RIGHT if velocity.x > 0 else Vector2.LEFT
		else:
			last_direction = Vector2.DOWN if velocity.y > 0 else Vector2.UP
		_play_anim("Walk")

func _play_anim(type: String):
	var dir_name = "Down"
	if last_direction == Vector2.UP: dir_name = "Up"
	elif last_direction == Vector2.LEFT: dir_name = "Left"
	elif last_direction == Vector2.RIGHT: dir_name = "Right"
	
	if sprite.sprite_frames.has_animation(type + dir_name):
		sprite.play(type + dir_name)

# --- Dynamic Battle Loading ---
func _on_battle_trigger(body: Node) -> void:
	print("Something entered the trigger: ", body.name) # DEBUG LINE
	if body.is_in_group("player"):
		print("Player detected! Starting combat...") # DEBUG LINE
		_start_combat()

func _start_combat() -> void:
	get_tree().paused = true
	
	var scene_resource = load(battle_scene_file)
	if not scene_resource:
		print("Critical Error: Battle scene file not found at ", battle_scene_file)
		get_tree().paused = false
		return
		
	var battle_node = scene_resource.instantiate()
	
	# Assumes your main scene has a CanvasLayer node
	var canvas = get_tree().current_scene.find_child("CanvasLayer", true, false)
	if canvas:
		canvas.add_child(battle_node)
	else:
		get_tree().current_scene.add_child(battle_node)
	
	battle_node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if battle_node.has_method("start_battle"):
		battle_node.start_battle()
	
	if not battle_node.is_connected("battle_finished", _on_battle_finished):
		battle_node.battle_finished.connect(_on_battle_finished)

func _on_battle_finished(victory: bool) -> void:
	get_tree().paused = false
	if victory:
		die()

func die() -> void:
	emit_signal("enemy_died", self)
	queue_free()
