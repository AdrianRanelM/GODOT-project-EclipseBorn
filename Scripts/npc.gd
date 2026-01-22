extends ConversationNPC

func _load_initial_dialogue() -> void:
	# Randomize their dialogue
	var lines = [
		"Nice weather today.",
		"Oh, hello traveler!",
		"My back hurts."
	]
	push_line(lines.pick_random())
