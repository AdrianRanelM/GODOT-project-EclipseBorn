extends Control

@export var images: Array[Texture2D]
@export var subtitles: Array[String] = ["", "", ""]
@onready var texture_rect = $TextureRect
@onready var prompt_label = $PromptLabel
@onready var subtitle_label = $SubtitleLabel
@onready var bgm_player = $bgmplayer
@onready var sfx_player_ui = $sfxplayer_ui
@onready var sfx_player_mirror = $sfxplayer_mirrorbreak
@onready var fade_overlay = $FadeOverlay

@export var background_music: AudioStream
@export var button_click_sound: AudioStream
@export var mirror_break_sound: AudioStream

enum TransitionType {FADE, SLIDE, ZOOM, MORPH}
@export var transition_type: TransitionType = TransitionType.FADE

var current_index = 0
var can_advance = false

func _ready():
	# Make TextureRect fill screen
	texture_rect.size = get_viewport_rect().size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	   
	# Setup fade overlay
	fade_overlay.size = get_viewport_rect().size
	fade_overlay.color = Color.BLACK
	fade_overlay.visible = true
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 1)
	stylebox.content_margin_left = 20   
	stylebox.content_margin_right = 20 
	stylebox.content_margin_top = 10   
	stylebox.content_margin_bottom = 10 
	
	subtitle_label.add_theme_stylebox_override("normal", stylebox)
	prompt_label.add_theme_stylebox_override("normal", stylebox)
	
	# Set default volumes
	bgm_vol(0.1) 
	sfx_vol(0.5)   
	
	if background_music:
		bgm_player.stream = background_music
		bgm_player.play()
	
	# Fade in for slide 0
	fade_in_transition()
	show_image(0)

func fade_in_transition():
	# Fade from black to clear
	fade_overlay.modulate.a = 1.0  # Start black
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 3.0)
	await tween.finished

func fade_out_transition():
	# Fade from clear to black
	fade_overlay.modulate.a = 0.0  # Start clear
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
	await tween.finished

func transition_with_morph(next_image):
	match transition_type:
		TransitionType.MORPH:
			# PowerPoint-like morph with multiple properties
			var tween = create_tween()
			tween.set_parallel(true)

			# Scale animation
			tween.tween_property(texture_rect, "scale", 
				Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_CUBIC)
			tween.chain().tween_property(texture_rect, "scale",
				Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_CUBIC)

			# Rotation (subtle)
			tween.parallel().tween_property(texture_rect, "rotation",
				deg_to_rad(5), 0.3)
			tween.chain().tween_property(texture_rect, "rotation",
				deg_to_rad(0), 0.7)

			# Fade out old, fade in new
			tween.parallel().tween_property(texture_rect, "modulate:a",
				0.0, 0.5).set_delay(0.5)

			await tween.finished
			texture_rect.texture = next_image
			texture_rect.modulate.a = 1.0
			texture_rect.scale = Vector2(1.0, 1.0)  # Reset scale
			texture_rect.rotation = 0.0  # Reset rotation
		
		TransitionType.FADE:
			# Simple fade transition
			var tween = create_tween()
			tween.tween_property(texture_rect, "modulate:a", 0.0, 0.5)
			await tween.finished
			texture_rect.texture = next_image
			tween = create_tween()
			tween.tween_property(texture_rect, "modulate:a", 1.0, 0.5)
			await tween.finished
		
		TransitionType.ZOOM:
			# Zoom transition
			var tween = create_tween()
			tween.tween_property(texture_rect, "scale", Vector2(1.2, 1.2), 0.5)
			tween.parallel().tween_property(texture_rect, "modulate:a", 0.0, 0.5)
			await tween.finished
			texture_rect.texture = next_image
			texture_rect.scale = Vector2(0.8, 0.8)
			texture_rect.modulate.a = 0.0
			tween = create_tween()
			tween.tween_property(texture_rect, "scale", Vector2(1.0, 1.0), 0.5)
			tween.parallel().tween_property(texture_rect, "modulate:a", 1.0, 0.5)
			await tween.finished

func show_image(index):
	if index < images.size() and index < subtitles.size():
		# Play transition animation before changing content
		if current_index > 0:  # Don't transition on first slide
			await transition_with_morph(images[index])
		else:
			# For first slide, just set the image
			texture_rect.texture = images[index]
		
		# Check if we're transitioning from slide 1 to 2
		if current_index == 1 and index == 2 and mirror_break_sound:
			sfx_player_mirror.stream = mirror_break_sound
			sfx_player_mirror.play()
		
		subtitle_label.text = subtitles[index]
		current_index = index
		can_advance = false
		prompt_label.hide()
		
		# Check if this is the last slide (slide 9)
		if index == 9:
			await get_tree().create_timer(2.0).timeout
			fade_out_transition()
			await get_tree().create_timer(1.0).timeout
			get_tree().change_scene_to_file("res://scenes/main.tscn")  # <-- scene change here 
			return
		
		await get_tree().create_timer(0.5).timeout
		can_advance = true
		prompt_label.show()
	else:
		if current_index == 9:
			fade_out_transition()
			await get_tree().create_timer(1.0).timeout
		queue_free()

func _input(event):
	if can_advance and event.is_action_pressed("ui_interact"):
		if button_click_sound:
			if sfx_player_ui.playing:
				sfx_player_ui.stop() 
			sfx_player_ui.stream = button_click_sound
			sfx_player_ui.play()
		
		show_image(current_index + 1)

# Set BGM volume (0.0 to 1.0)
func bgm_vol(vol: float):
	bgm_player.volume_db = linear_to_db(clamp(vol, 0.0, 1.0))

# Set all SFX volume (0.0 to 1.0)
func sfx_vol(vol: float):
	var volume_db = linear_to_db(clamp(vol, 0.0, 1.0))
	sfx_player_ui.volume_db = volume_db
	sfx_player_mirror.volume_db = volume_db
