extends Control

@onready var quest_container = $PanelContainer/VBoxContainer/ScrollContainer/VBoxContainer

func _ready():
	# Nakatago ang menu sa simula
	self.hide()
	
	# Sample listahan ng quests
	var list_of_quests = ["Find the ancient lantern", "Talk to the village elder"]
	update_list(list_of_quests)

func update_list(quests):
	# Linisin ang mga lumang labels
	for child in quest_container.get_children():
		child.queue_free()
	
	for q_text in quests:
		var new_label = Label.new()
		new_label.text = "• " + q_text
		# I-apply ang font dito (preload mo ang Minecraft.ttf sa itaas)
		quest_container.add_child(new_label)

func _on_button_pressed():
	self.hide() # Isasara ang menu
