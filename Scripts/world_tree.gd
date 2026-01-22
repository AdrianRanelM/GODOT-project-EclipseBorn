extends ConversationNPC

func _load_initial_dialogue() -> void:
	# Randomize their dialogue
	var lines = [
		"There is an enemy up ahead,\n his name is Valerius.",
		"Be the Sun to those who are Sunless, Sunny."
	]
	push_line(lines.pick_random())
