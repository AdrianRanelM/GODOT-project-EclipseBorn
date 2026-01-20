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

# Inner Slide class (no top-level class_name)
class Slide:
	var texture = null
	var subtitle = ""
	var index = 0
	var next = null
	var is_last = false

	func _init(_texture = null, _subtitle = "", _index = 0) -> void:
		texture = _texture
		subtitle = _subtitle
		index = _index
		next = null
		is_last = false

# Linked-list state (no strict type annotations)
var head = null
var current_slide = null
var can_advance = false

# --- Volume helpers (defined before _ready) ---
func bgm_vol(vol: float) -> void:
	bgm_player.volume_db = linear_to_db(clamp(vol, 0.0, 1.0))

func sfx_vol(vol: float) -> void:
	var volume_db = linear_to_db(clamp(vol, 0.0, 1.0))
	sfx_player_ui.volume_db = volume_db
	sfx_player_mirror.volume_db = volume_db

# --- Fade transitions ---
func fade_in_transition() -> void:
	fade_overlay.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, 3.0)
	await tween.finished

func fade_out_transition() -> void:
	fade_overlay.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 1.0)
	await tween.finished

# --- Transition handler ---
func transition_with_morph(next_texture) -> void:
	match transition_type:
		TransitionType.MORPH:
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(texture_rect, "scale", Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_CUBIC)
			tween.chain().tween_property(texture_rect, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(texture_rect, "rotation", deg_to_rad(5), 0.3)
			tween.chain().tween_property(texture_rect, "rotation", deg_to_rad(0), 0.7)
			tween.parallel().tween_property(texture_rect, "modulate:a", 0.0, 0.5).set_delay(0.5)
			await tween.finished
			texture_rect.texture = next_texture
			texture_rect.modulate.a = 1.0
			texture_rect.scale = Vector2(1.0, 1.0)
			texture_rect.rotation = 0.0

		TransitionType.FADE:
			var tween = create_tween()
			tween.tween_property(texture_rect, "modulate:a", 0.0, 0.5)
			await tween.finished
			texture_rect.texture = next_texture
			tween = create_tween()
			tween.tween_property(texture_rect, "modulate:a", 1.0, 0.5)
			await tween.finished

		TransitionType.ZOOM:
			var tween = create_tween()
			tween.tween_property(texture_rect, "scale", Vector2(1.2, 1.2), 0.5)
			tween.parallel().tween_property(texture_rect, "modulate:a", 0.0, 0.5)
			await tween.finished
			texture_rect.texture = next_texture
			texture_rect.scale = Vector2(0.8, 0.8)
			texture_rect.modulate.a = 0.0
			tween = create_tween()
			tween.tween_property(texture_rect, "scale", Vector2(1.0, 1.0), 0.5)
			tween.parallel().tween_property(texture_rect, "modulate:a", 1.0, 0.5)
			await tween.finished

# --- Build linked list from arrays ---
func _build_linked_list() -> void:
	head = null
	var prev = null
	var count = min(images.size(), subtitles.size())
	for i in range(count):
		var s = Slide.new(images[i], subtitles[i], i)
		if head == null:
			head = s
		if prev:
			prev.next = s
		prev = s
	if prev:
		prev.is_last = true

# --- Show a slide (defined before _ready) ---
func _show_slide(slide) -> void:
	if slide == null:
		queue_free()
		return

	if current_slide != null:
		await transition_with_morph(slide.texture)
	else:
		texture_rect.texture = slide.texture

	# Mirror break sound trigger preserved exactly
	if current_slide and current_slide.index == 1 and slide.index == 2 and mirror_break_sound:
		sfx_player_mirror.stream = mirror_break_sound
		sfx_player_mirror.play()

	subtitle_label.text = slide.subtitle
	current_slide = slide
	can_advance = false
	prompt_label.hide()

	# Last-slide behavior preserved (index 9 and scene path unchanged)
	if slide.index == 9 or slide.is_last:
		await get_tree().create_timer(2.0).timeout
		await fade_out_transition()
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	await get_tree().create_timer(0.5).timeout
	can_advance = true
	prompt_label.show()

# --- Ready: setup and start ---
func _ready() -> void:
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

	# Build linked list and show first slide
	_build_linked_list()
	await fade_in_transition()
	if head:
		_show_slide(head)

# --- Input handling ---
func _input(event) -> void:
	if can_advance and event.is_action_pressed("ui_interact"):
		if button_click_sound:
			if sfx_player_ui.playing:
				sfx_player_ui.stop()
			sfx_player_ui.stream = button_click_sound
			sfx_player_ui.play()

		if current_slide and current_slide.next:
			_show_slide(current_slide.next)
		elif current_slide == null and head:
			_show_slide(head)
		else:
			if current_slide and current_slide.index == 9:
				await fade_out_transition()
				await get_tree().create_timer(1.0).timeout
			queue_free()
