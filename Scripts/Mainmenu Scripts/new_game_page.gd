extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main.tscn")

func _back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Start-page.tscn") # Replace with function body.
