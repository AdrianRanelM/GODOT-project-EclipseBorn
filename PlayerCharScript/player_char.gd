extends CharacterBody2D

var max_speed = 75
var last_direction = Vector2(1,0)

# inventory
@onready var inventory_ui = $CanvasLayer/InventoryUI
@onready var pickup_area: Area2D = $PickupArea
var inventory_unlocked: bool = false
var count = 0

# map/camera
@onready var camera: Camera2D = find_child("Camera2D", true, false)
var current_tilemap: TileMap = null

# items
@export var inv = Inv
@export var inventory: Inv
var nearby_item: Area2D = null

func _ready() -> void:
	add_to_group("player")
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)
	PlayerStats.hp_changed.connect(_on_hp_changed)
	PlayerStats.mp_changed.connect(_on_mp_changed)
	inventory_ui.connect_player(self)
	
	# Initial camera setup (Using call_deferred to ensure map is loaded)
	call_deferred("update_camera_limits", "world")

# ---------------------------------------------------------
#  FIXED CAMERA LOGIC: Name Search + Auto-Detect Fallback
# ---------------------------------------------------------
func update_camera_limits(world_node_name: String) -> void:
	var target_tilemap: TileMap = null
	
	print("--- Camera Update Triggered for: ", world_node_name, " ---")

	# 1. Try to find the map by NAME first
	var world_node = get_tree().root.find_child(world_node_name, true, false)
	if world_node:
		target_tilemap = world_node.find_child("*TileMap*", true, false)
	
	# 2. FAIL-SAFE: If name search failed, find the map under the player's feet
	if target_tilemap == null:
		print("Warning: Could not find map named '", world_node_name, "'. Scanning for nearby map...")
		target_tilemap = _find_tilemap_under_player()

	# 3. Apply the limits if a map was found
	if target_tilemap:
		current_tilemap = target_tilemap
		_apply_camera_limits(target_tilemap)
	else:
		print("CRITICAL ERROR: No TileMap found! Camera limits NOT updated.")

func _find_tilemap_under_player() -> TileMap:
	# Get ALL TileMaps in the current scene
	var all_tilemaps = get_tree().current_scene.find_children("*", "TileMap", true, false)
	
	for tm in all_tilemaps:
		if tm is TileMap:
			# Convert player global position to the TileMap's local coordinate system
			var local_pos = tm.to_local(global_position)
			# Convert local pixel position to map (grid) coordinates
			var map_coords = tm.local_to_map(local_pos)
			
			# Check if the player is standing inside the drawn area of this map
			if tm.get_used_rect().has_point(map_coords):
				print("Auto-Detected Map: ", tm.get_parent().name)
				return tm
	return null

func _apply_camera_limits(tm: TileMap) -> void:
	var rect = tm.get_used_rect()
	var cell_size = tm.tile_set.tile_size
	var world_origin = tm.global_position 

	# UNLOCK camera momentarily
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000
	
	camera.reset_smoothing()
	camera.force_update_scroll()

	# LOCK to new boundaries
	camera.limit_left   = int(world_origin.x + (rect.position.x * cell_size.x))
	camera.limit_top    = int(world_origin.y + (rect.position.y * cell_size.y))
	camera.limit_right  = int(world_origin.x + (rect.end.x * cell_size.x))
	camera.limit_bottom = int(world_origin.y + (rect.end.y * cell_size.y))
	
	print("SUCCESS: Camera limits snapped to new map.")
# ---------------------------------------------------------

func _input(event):
	if event.is_action_pressed("ToggleInventory"):
		if inventory_unlocked:
			inventory_ui.visible = !inventory_ui.visible
		else:
			print("Inventory is locked!")

	elif event.is_action_pressed("PickItemUp") and nearby_item:
		if inventory_unlocked:
			nearby_item.pick_up(self)
		else:
			print("Inventory is locked! Cannot pick up items.")

func soulbelt() -> void:
	count += 1
	unlock_inventory() # Check unlock immediately

func unlock_inventory() -> void:
	if count >= 3: # Changed to >= just in case
		inventory_unlocked = true
	else:
		inventory_unlocked = false

func add_item(item: InvItem):
	inventory.add_item(item)
	inventory_ui.update_inventory(inventory)

func _on_body_entered(body: Node) -> void:
	if body is Area2D and body.has_method("get_item"):
		nearby_item = body

func _on_body_exited(body: Node) -> void:
	if body == nearby_item:
		nearby_item = null

func receive_item(item: InvItem, world_item: Node) -> void:
	if not inventory_unlocked:
		print("Inventory is locked! Cannot pick up items.")
		return

	if inventory.add_item(item):
		inventory_ui.update_inventory(inventory)
		world_item.queue_free()
	else:
		print("Inventory full! Cannot pick up.")

func _physics_process(_delta):
	z_index = int(global_position.y)
	var direction = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	
	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * max_speed
		move_and_slide()
		last_direction = direction
		play_walk_animation(direction)
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		play_idle_animation(last_direction)

func play_walk_animation(direction):
	if direction.x > 0: $AnimatedSprite2D.play("WalkRight")
	elif direction.x < 0: $AnimatedSprite2D.play("WalkLeft")
	elif direction.y > 0: $AnimatedSprite2D.play("WalkDown")
	elif direction.y < 0: $AnimatedSprite2D.play("WalkUp")

func play_idle_animation(direction):
	if direction.x > 0: $AnimatedSprite2D.play("IdleRight")
	elif direction.x < 0: $AnimatedSprite2D.play("IdleLeft")
	elif direction.y > 0: $AnimatedSprite2D.play("IdleDown")
	elif direction.y < 0: $AnimatedSprite2D.play("IdleUp")

func _on_hp_changed(current_hp: int, max_hp: int) -> void:
	inventory_ui._on_player_hp_changed(current_hp, max_hp)

func _on_mp_changed(current_mp: int, max_mp: int) -> void:
	inventory_ui._on_player_mp_changed(current_mp, max_mp)
