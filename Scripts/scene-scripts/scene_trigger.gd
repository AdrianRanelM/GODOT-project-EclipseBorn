extends Area2D
class_name MapTeleport

enum World {
	WORLD_1,
	WORLD_2,
	WORLD_3
}

# THE FIX: Tell this specific teleporter where to send the player
@export var target_world: World = World.WORLD_2 
@export var transition_scene: PackedScene

# --- WORLD SPAWN POSITIONS ---
const WORLD_POSITIONS: Dictionary = {
	World.WORLD_1: Vector2(1938, 40),
	World.WORLD_2: Vector2(236, 1037),
	World.WORLD_3: Vector2(424, 1455),
}

# --- WORLD ROOT NODE NAMES ---
const WORLD_NODES: Dictionary = {
	World.WORLD_1: "world",
	World.WORLD_2: "inside_wiz_tower",
	World.WORLD_3: "valerius_room",
}

var _player: Node2D
var is_teleporting: bool = false 

func _ready() -> void:
	# Cleaned up: No auto-detect, only one connection
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if is_teleporting or not body.is_in_group("player"):
		return

	_player = body
	is_teleporting = true
	
	# We go directly to the world selected in the Inspector
	var destination_pos = WORLD_POSITIONS[target_world]
	var destination_name = WORLD_NODES[target_world]

	# Handle collisions and teleport
	_disable_other_world_collisions(target_world)
	_play_transition_and_teleport(destination_pos, destination_name)

func _play_transition_and_teleport(target_position: Vector2, world_name: String) -> void:
	if transition_scene == null: 
		is_teleporting = false
		return

	var transition = transition_scene.instantiate()
	get_tree().current_scene.add_child(transition)
	var anim = transition.get_node_or_null("AnimationPlayer")
	
	if anim: anim.play("transition")
	
	# Wait for black screen
	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(_player):
		_player.global_position = target_position
		
		# Give physics a moment to catch up
		await get_tree().process_frame
		await get_tree().process_frame
		
		if _player.has_method("update_camera_limits"):
			_player.update_camera_limits(world_name)
	
	if anim and is_instance_valid(anim):
		await anim.animation_finished
	
	if is_instance_valid(transition):
		transition.queue_free()
	
	# Small cooldown to prevent double-triggering
	await get_tree().create_timer(0.3).timeout
	is_teleporting = false

# --------------------------------
# COLLISION CONTROL
# --------------------------------
func _disable_other_world_collisions(active_world: World) -> void:
	for world_id in WORLD_NODES.keys():
		var node_name = WORLD_NODES[world_id]
		var world_node = get_tree().root.find_child(node_name, true, false)
		
		if world_node:
			_set_collision_enabled(world_node, world_id == active_world)

func _set_collision_enabled(node: Node, enabled: bool) -> void:
	for child in node.get_children():
		if child is CollisionObject2D or child is TileMap:
			child.set_deferred("collision_layer", 1 if enabled else 0)
			child.set_deferred("collision_mask", 1 if enabled else 0)
