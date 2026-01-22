extends CanvasLayer
class_name SceneManager

@onready var _fade_player: AnimationPlayer = $AnimationPlayer
var _is_transitioning: bool = false

# =========================
# PUBLIC TELEPORT FUNCTION
# =========================
func teleport_with_transition(target_position: Vector2) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	call_deferred("_teleport_internal", target_position)

# =========================
# INTERNAL LOGIC
# =========================
func _teleport_internal(target_position: Vector2) -> void:
	# Fade out
	if _fade_player and _fade_player.has_animation("fade_out"):
		_fade_player.play("fade_out")

	# Wait exactly 0.5 seconds (teleport moment)
	await get_tree().create_timer(0.5).timeout

	# Teleport player
	_teleport_player(target_position)

	# Fade in
	if _fade_player and _fade_player.has_animation("fade_in"):
		_fade_player.play("fade_in")
		await _fade_player.animation_finished

	_is_transitioning = false

# =========================
# PLAYER TELEPORT
# =========================
func _teleport_player(target_position: Vector2) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("SceneManager: Player not found.")
		return

	if player is Node2D:
		# Reset velocity safely
		if player.has_variable("velocity"):
			player.velocity = Vector2.ZERO

		player.global_position = target_position

	# Snap camera
	var cam: Camera2D = _find_camera(player)
	if cam:
		var was_smoothing : bool = cam.smoothing_enabled
		cam.smoothing_enabled = false
		cam.global_position = target_position
		cam.make_current()
		if was_smoothing:
			call_deferred("_restore_camera_smoothing", cam)

func _restore_camera_smoothing(cam: Camera2D) -> void:
	if cam and cam.is_inside_tree():
		cam.smoothing_enabled = true

func _find_camera(player: Node) -> Camera2D:
	if player:
		var cam_child := player.get_node_or_null("Camera2D")
		if cam_child and cam_child is Camera2D:
			return cam_child

	return get_viewport().get_camera_2d()
