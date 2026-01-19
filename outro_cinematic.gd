extends Control

@export var images: Array[Texture2D]
@export var subtitles: Array[String] = ["", "", "", "", "", "", ""]  # Changed to 7 elements for new scenes
@onready var texture_rect = $TextureRect
@onready var prompt_label = $PromptLabel
@onready var subtitle_label = $SubtitleLabel
@onready var bgm_player = $bgmplayer
@onready var sfx_player_ui = $sfxplayer_ui
@onready var sfx_player_mirror = $sfxplayer_mirrorbreak
@onready var sfx_player_wind = $sfxplayer_wind
@onready var sfx_player_crystal = $sfxplayer_crystal
@onready var fade_overlay = $FadeOverlay

@export var background_music: AudioStream
@export var button_click_sound: AudioStream
@export var mirror_break_sound: AudioStream
@export var wind_sound: AudioStream
@export var crystal_sound: AudioStream
@export var final_bgm: AudioStream

enum TransitionType {FADE, SLIDE, ZOOM, MORPH}
@export var transition_type: TransitionType = TransitionType.FADE

var current_index = 0
var can_advance = false
var prompt_visible = false
var bgm_target_volume: float = 0.1  # Store BGM volume separately
var is_final_bgm_playing = false  # Track which BGM is playing

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
    stylebox.bg_color = Color(0, 0, 0, 0.7)  # Slightly transparent for better readability
    stylebox.content_margin_left = 20   
    stylebox.content_margin_right = 20 
    stylebox.content_margin_top = 10   
    stylebox.content_margin_bottom = 10 
    
    subtitle_label.add_theme_stylebox_override("normal", stylebox)
    prompt_label.add_theme_stylebox_override("normal", stylebox)
    
    # Set default volumes
    bgm_vol(0.1)  # This sets bgm_target_volume
    sfx_vol(0.5)
    wind_vol(0.7)
    crystal_vol(0.6)
    
    # DEBUG: Check if background music is set
    if background_music:
        print("Background music loaded: ", background_music.resource_path)
        bgm_player.stream = background_music
        bgm_player.play()
        is_final_bgm_playing = false
    else:
        print("WARNING: Background music not set!")
    
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
    tween.tween_property(fade_overlay, "modulate:a", 1.0, 2.0)
    await tween.finished

func transition_with_morph(next_image):
    match transition_type:
        TransitionType.MORPH:
            var tween = create_tween()
            tween.set_parallel(true)
            tween.tween_property(texture_rect, "scale", 
                Vector2(1.1, 1.1), 0.5).set_trans(Tween.TRANS_CUBIC)
            tween.chain().tween_property(texture_rect, "scale",
                Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_CUBIC)
            tween.parallel().tween_property(texture_rect, "rotation",
                deg_to_rad(5), 0.3)
            tween.chain().tween_property(texture_rect, "rotation",
                deg_to_rad(0), 0.7)
            tween.parallel().tween_property(texture_rect, "modulate:a",
                0.0, 0.5).set_delay(0.5)
            await tween.finished
            texture_rect.texture = next_image
            texture_rect.modulate.a = 1.0
            texture_rect.scale = Vector2(1.0, 1.0)
            texture_rect.rotation = 0.0
        
        TransitionType.FADE:
            var tween = create_tween()
            tween.tween_property(texture_rect, "modulate:a", 0.0, 0.5)
            await tween.finished
            texture_rect.texture = next_image
            tween = create_tween()
            tween.tween_property(texture_rect, "modulate:a", 1.0, 0.5)
            await tween.finished
        
        TransitionType.ZOOM:
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

func play_slide_transition_sfx(old_index: int, new_index: int):
    # Mirror break between scene 1 and 2
    if old_index == 0 and new_index == 1 and mirror_break_sound:
        sfx_player_mirror.stream = mirror_break_sound
        sfx_player_mirror.play()
    
    # Wind SFX between scene 2 and 3
    if old_index == 1 and new_index == 2 and wind_sound:
        sfx_player_wind.stream = wind_sound
        sfx_player_wind.play()
    
    if old_index == 3 and new_index == 4 and crystal_sound:
        sfx_player_crystal.stream = crystal_sound
        sfx_player_crystal.play()
    
    # BGM change between scene 6 and 7 (new final scene)
    if old_index == 5 and new_index == 6 and final_bgm:
        change_bgm(final_bgm, 0.2)  # Changed from 0 to 2.0 for proper fade

func change_bgm(new_music: AudioStream, fade_duration: float = 2.0):  # Default to 2.0 seconds
    # Fade out current BGM if it's playing
    if bgm_player.playing and fade_duration > 0:
        var tween = create_tween()
        tween.tween_property(bgm_player, "volume_db", -60.0, fade_duration/2)
        await tween.finished
    elif bgm_player.playing:
        # If fade_duration is 0, just stop immediately
        bgm_player.stop()
    
    # Change to new music
    bgm_player.stream = new_music
    bgm_player.play()
    
    # Fade in new BGM to target volume
    if fade_duration > 0:
        bgm_player.volume_db = -80.0  # Start silent
        var tween = create_tween()
        tween.tween_property(bgm_player, "volume_db", linear_to_db(bgm_target_volume), fade_duration/2)
    else:
        bgm_player.volume_db = linear_to_db(bgm_target_volume)
    
    # Update tracking
    is_final_bgm_playing = (new_music == final_bgm)

func show_image(index):
    if index < images.size() and index < subtitles.size():
        # Play transition animation before changing content
        if current_index > 0:
            await transition_with_morph(images[index])
        else:
            texture_rect.texture = images[index]
        
        # Play slide-specific transition SFX (and BGM change)
        play_slide_transition_sfx(current_index, index)
        
        subtitle_label.text = subtitles[index]
        current_index = index
        can_advance = false
        prompt_visible = false
        prompt_label.hide()  # Hide prompt immediately
        
        # FASTER SUBTITLE APPEARANCE - Reduced timers
        # 1. Very short lockout timer (0.3s) - can advance after this
        await get_tree().create_timer(0.3).timeout
        can_advance = true
        
        # 2. Much shorter prompt timer (1.5s total) - prompt appears faster
        await get_tree().create_timer(1.2).timeout  # Total 1.5s from start
        if can_advance:  # Only show if still on same slide
            prompt_visible = true
            
            # Fade in the prompt label quickly
            prompt_label.modulate.a = 0.0  # Start transparent
            prompt_label.show()
            var tween = create_tween()
            tween.tween_property(prompt_label, "modulate:a", 1.0, 0.3)  # Faster fade in
        
        # Check if this is the last slide (slide 6 for 7 scenes total)
        if index == 6:  # Changed from 5 to 6 for new final scene
            await get_tree().create_timer(3.0).timeout
            fade_out_transition()
            await get_tree().create_timer(2.0).timeout
            queue_free()
            return
    else:
        if current_index == 6:  # Changed from 5 to 6
            fade_out_transition()
            await get_tree().create_timer(2.0).timeout
        queue_free()

func _input(event):
    if can_advance and event.is_action_pressed("ui_interact"):
        if button_click_sound:
            if sfx_player_ui.playing:
                sfx_player_ui.stop() 
            sfx_player_ui.stream = button_click_sound
            sfx_player_ui.play()
        
        show_image(current_index + 1)

# VOLUME CONTROL FUNCTIONS
func bgm_vol(vol: float):
    bgm_target_volume = clamp(vol, 0.0, 1.0)
    bgm_player.volume_db = linear_to_db(bgm_target_volume)

func sfx_vol(vol: float):
    var volume_db = linear_to_db(clamp(vol, 0.0, 1.0))
    sfx_player_ui.volume_db = volume_db
    sfx_player_mirror.volume_db = volume_db

func wind_vol(vol: float):
    sfx_player_wind.volume_db = linear_to_db(clamp(vol, 0.0, 1.0))

func crystal_vol(vol: float):
    sfx_player_crystal.volume_db = linear_to_db(clamp(vol, 0.0, 1.0))

func set_all_sfx_volume(vol: float):
    var volume_db = linear_to_db(clamp(vol, 0.0, 1.0))
    sfx_player_ui.volume_db = volume_db
    sfx_player_mirror.volume_db = volume_db
    sfx_player_wind.volume_db = volume_db
    sfx_player_crystal.volume_db = volume_db

# DEBUG FUNCTION - Add this to check BGM status
func _process(_delta):
    # You can remove this after debugging
    if Engine.get_frames_drawn() % 60 == 0:  # Print every second
        if bgm_player.playing:
            print("BGM playing: ", bgm_player.stream.resource_path if bgm_player.stream else "None", 
                  " | Volume: ", bgm_player.volume_db, "dB")
        else:
            print("BGM NOT PLAYING!")
