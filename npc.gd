extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var proximity_area: Area2D = $Area2D


@export var dialogue_ui_path: NodePath
@onready var dialogue_ui: Control = $"../Player/CanvasLayer/DialogueUI"

var player_ref: Node = null
var can_talk: bool = false

# Conversation stack instance (ConversationStack must be class_name ConversationStack)
var convo_stack: ConversationStack = ConversationStack.new()

func _ready() -> void:
	# Connect area signals
	proximity_area.body_entered.connect(_on_proximity_body_entered)
	proximity_area.body_exited.connect(_on_proximity_body_exited)

	# Resolve dialogue UI safely
	if dialogue_ui_path != NodePath(""):
		dialogue_ui = get_node_or_null(dialogue_ui_path)
		if dialogue_ui == null:
			push_warning("Dialogue UI path not found: %s" % dialogue_ui_path)
		else:
			# optional: ensure the UI has the expected methods
			if dialogue_ui.has_method("hide_ui"):
				dialogue_ui.hide_ui()
			else:
				push_warning("Dialogue UI does not implement hide_ui()")

func _on_proximity_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body
		can_talk = true
		
		_face_player()

func _on_proximity_body_exited(body: Node) -> void:
	if body == player_ref:
		player_ref = null
		can_talk = false
		convo_stack.clear()
		if dialogue_ui and dialogue_ui.has_method("hide_ui"):
			dialogue_ui.hide_ui()

func _process(delta: float) -> void:
	z_index = int(global_position.y)
	if player_ref:
		_face_player()

	if can_talk and Input.is_action_just_pressed("TalkToNPC"):
		dialogue_ui.visible = true
		_on_talk_pressed()

func _face_player() -> void:
	if not player_ref:
		return
	sprite.flip_h = (player_ref.global_position.x > global_position.x)

# Called when player presses the talk key
func _on_talk_pressed() -> void:
	if convo_stack.is_empty():
		_push_initial_conversation()
	_show_current_frame()

# Example initial conversation
func _push_initial_conversation() -> void:
	convo_stack.push({"speaker":"Guy", "text":"Hey there, traveler.", "meta":null})

# Show the current frame in the Dialogue UI
func _show_current_frame() -> void:
	# If no UI, print to console and pop
	if dialogue_ui == null:
		var peek = convo_stack.peek()
		if peek.is_empty():
			return
		print("Talking to player:", peek.get("text", ""))
		convo_stack.pop()
		return

	# Get the top frame
	var frame = convo_stack.peek()
	if frame.is_empty():
		# nothing to show
		if dialogue_ui.has_method("hide_ui"):
			dialogue_ui.hide_ui()
		return

	# Show the frame in the UI first, then pop it from the stack
	if dialogue_ui.has_method("show_frame"):
		dialogue_ui.show_frame(frame)
	else:
		# fallback: print if UI doesn't implement show_frame
		print("Dialogue UI missing show_frame():", frame.get("text", ""))
	convo_stack.pop()

	# Handle any meta actions after showing
	_handle_frame_meta(frame)

func _handle_frame_meta(frame: Dictionary) -> void:
	var meta = frame.get("meta", null)
	if meta == null:
		return
	if meta is Dictionary and meta.has("action"):
		match meta["action"]:
			"offer_quest":
				convo_stack.push({"speaker":"Player", "text":"Yes, tell me more.", "meta":{"action":"accept_quest"}})
				convo_stack.push({"speaker":"Player", "text":"No thanks.", "meta":{"action":"decline_quest"}})
			"accept_quest":
				print("Quest accepted")
			"decline_quest":
				print("Quest declined")

# Helper methods to change NPC text at runtime
func push_npc_line(text: String, meta = null) -> void:
	convo_stack.push({"speaker":"Guy", "text": text, "meta": meta})

func replace_top_line(text: String, meta = null) -> void:
	var frame = {"speaker":"Guy", "text": text, "meta": meta}
	if not convo_stack.is_empty():
		convo_stack.pop()
	convo_stack.push(frame)
