extends Control

@onready var speaker_label: Label = $TextureRect/SpeakerLabel
@onready var text_label: Label = $TextureRect/TextLabel

func show_frame(frame: Dictionary) -> void:
	if frame.is_empty():
		visible = false
		return
	speaker_label.text = frame.get("speaker", "")
	text_label.text = frame.get("text", "")
	visible = true

func hide_ui() -> void:
	visible = false
