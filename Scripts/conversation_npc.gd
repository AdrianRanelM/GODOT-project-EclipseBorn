class_name ConversationNPC
extends CharacterBody2D

# --- Configuration ---
@export var npc_name: String = "Stranger"
@export var dialogue_ui_path: NodePath

# --- Internal References ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var proximity_area: Area2D = $Area2D
@onready var dialogue_ui: Control = get_node_or_null(dialogue_ui_path)

# --- State ---
var player_ref: Node = null
var can_talk: bool = false
var convo_stack: Stack = Stack.new()

func _ready() -> void:
	# 1. DEBUG: Check Area2D
	if not proximity_area:
		printerr("CRITICAL: Area2D is missing from ", name)
	else:
		if not proximity_area.body_entered.is_connected(_on_proximity_body_entered):
			proximity_area.body_entered.connect(_on_proximity_body_entered)
		if not proximity_area.body_exited.is_connected(_on_proximity_body_exited):
			proximity_area.body_exited.connect(_on_proximity_body_exited)
	
	# 2. DEBUG: Check UI
	if dialogue_ui == null:
		# This looks through the whole game for a node named "DialogueUI"
		dialogue_ui = get_tree().root.find_child("DialogueUI", true, false)
	
	if dialogue_ui:
		print("SUCCESS: NPC '", npc_name, "' found Dialogue UI via search.")
		if dialogue_ui.has_method("hide_ui"):
			dialogue_ui.hide_ui()
	else:
		printerr("ERROR: NPC '", npc_name, "' still cannot find Dialogue UI!")

func _process(_delta: float) -> void:
	z_index = int(global_position.y)

	if can_talk:
		# 3. DEBUG: Verify Input
		if Input.is_action_just_pressed("TalkToNPC"):
			print("INPUT DETECTED: 'TalkToNPC' pressed.")
			
			if dialogue_ui:
				dialogue_ui.visible = true
				print("UI set to visible.")
			
			_on_talk_pressed()

func _on_proximity_body_entered(body: Node) -> void:
	# 4. DEBUG: Check who entered
	print("Body entered NPC range: ", body.name)
	
	if body.is_in_group("player"):
		print("Player recognized! can_talk = true")
		player_ref = body
		can_talk = true

func _on_proximity_body_exited(body: Node) -> void:
	if body == player_ref:
		print("Player left range. can_talk = false")
		player_ref = null
		can_talk = false
		convo_stack.clear()
		if dialogue_ui and dialogue_ui.has_method("hide_ui"):
			dialogue_ui.hide_ui()

# ==========================================
# VIRTUAL FUNCTIONS (Override these in child scripts)
# ==========================================
func _on_talk_pressed() -> void:
	if convo_stack.is_empty():
		_load_initial_dialogue()
	_show_current_frame()

func _show_current_frame() -> void:
	var frame = convo_stack.peek()
	if frame.is_empty():
		if dialogue_ui and dialogue_ui.has_method("hide_ui"):
			dialogue_ui.hide_ui()
		return

	if dialogue_ui and dialogue_ui.has_method("show_frame"):
		dialogue_ui.show_frame(frame)
	else:
		# If this prints, your UI is missing or broken
		print("DEBUG [", npc_name, "]: ", frame.get("text", "..."))

	convo_stack.pop()
	_handle_frame_meta(frame)

func _handle_frame_meta(frame: Dictionary) -> void:
	var meta = frame.get("meta", null)
	if meta is Dictionary and meta.has("action"):
		_on_custom_action(meta["action"])

func push_line(text: String, meta = null, speaker_override: String = "") -> void:
	var speaker = speaker_override if speaker_override != "" else npc_name
	convo_stack.push({"speaker": speaker, "text": text, "meta": meta})

# VIRTUAL FUNCTIONS
func _load_initial_dialogue() -> void:
	push_line("...")

func _on_custom_action(action_id: String) -> void:
	pass
