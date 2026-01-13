extends Control

func _on_button_2_pressed():
	var username = $LineEdit.text
	if username == "": return
	
	var config = ConfigFile.new()
	config.set_value("Player", "name", username)
	
	# Logic to find the first empty slot
	var slot_to_save = 1
	for i in range(1, 4):
		if not FileAccess.file_exists("user://save_account_" + str(i) + ".cfg"):
			slot_to_save = i
			break
	
	var err = config.save("user://save_account_" + str(slot_to_save) + ".cfg")
	
	if err == OK:
		print("Saved " + username + " to Slot " + str(slot_to_save))
		get_tree().change_scene_to_file("res://Start-page.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Start-page.tscn") # Replace with function body.
