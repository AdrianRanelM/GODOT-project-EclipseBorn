extends Control

var my_font = preload("res://Minecraft.ttf") 

# Target all three buttons
@onready var slots = [
	$CanvasLayer/ScrollContainer/VBoxContainer/Button,
	$CanvasLayer/ScrollContainer/VBoxContainer/Button2,
	$CanvasLayer/ScrollContainer/VBoxContainer/Button3
]

func _ready():
	update_load_slots()

func update_load_slots():
	for i in range(3):
		var slot_num = i + 1
		var config = ConfigFile.new()
		var err = config.load("user://save_account_" + str(slot_num) + ".cfg")
		
		if err == OK:
			var saved_name = config.get_value("Player", "name")
			slots[i].text = str(saved_name)
			slots[i].add_theme_font_override("font", my_font)
			slots[i].add_theme_font_size_override("font_size", 50)
		else:
			slots[i].text = "No File"

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Start-page.tscn") # Replace with function body.
