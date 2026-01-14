extends Control

@export var images: Array[Texture2D]
@export var subtitles: Array[String] = ["", "", ""]
@onready var texture_rect = $TextureRect
@onready var prompt_label = $PromptLabel
@onready var subtitle_label = $SubtitleLabel  # Configured in editor

var current_index = 0
var can_advance = false

func _ready():
	# Make TextureRect fill screen
	texture_rect.size = get_viewport_rect().size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 1)  # Black, 70% opacity
	stylebox.corner_radius_top_left = 25
	stylebox.corner_radius_top_right = 25
	stylebox.corner_radius_bottom_left = 25
	stylebox.corner_radius_bottom_right = 25
	
	# Apply to label 
	subtitle_label.add_theme_stylebox_override("normal", stylebox)
	prompt_label.add_theme_stylebox_override("normal", stylebox)
	show_image(0)

func show_image(index):
	if index < images.size() and index < subtitles.size():
		texture_rect.texture = images[index]
		subtitle_label.text = subtitles[index]
		current_index = index
		can_advance = false
		prompt_label.hide()
		
		await get_tree().create_timer(0.5).timeout
		can_advance = true
		prompt_label.show()
	else:
		queue_free()

func _input(event):
	if can_advance and event.is_action_pressed("ui_interact"):
		show_image(current_index + 1)
