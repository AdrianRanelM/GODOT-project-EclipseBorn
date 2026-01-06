extends CharacterBody2D

var max_speed = 100
var last_direction = Vector2(1,0)

#inventory
@onready var animated_inventory = $CanvasLayer/InventoryUI
@onready var pickup_area: Area2D = $PickupArea

func _input(event):
	if event.is_action_pressed("ToggleInventory"):
		animated_inventory.visible = !animated_inventory.visible
	elif event.is_action_pressed("PickItemUp") and nearby_item:
		nearby_item.pick_up(self)

#items
@export var inv = Inv
@export var inventory: Inv
@onready var inventory_ui = $CanvasLayer/InventoryUI

func add_item(item: InvItem):
	inventory.add_item(item)
	inventory_ui.update_inventory(inventory)

var nearby_item: Area2D = null

func _ready() -> void:
	add_to_group("player")
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	# Detect if the body is a world item
	if body is Area2D and body.has_method("get_item"):
		nearby_item = body

func _on_body_exited(body: Node) -> void:
	if body == nearby_item:
		nearby_item = null

# Called by WorldItem when picked up
func receive_item(item: InvItem, world_item: Node) -> void:
	if inventory.add_item(item):
		inventory_ui.update_inventory(inventory)
		world_item.queue_free()  # remove item from world
	else:
		print("Inventory full! Cannot pick up.")
		# Optional: flash UI or play sound

#movement
func _physics_process(_delta):
	var direction = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	velocity = direction * max_speed 
	move_and_slide()
	
	if direction.length() > 0:
		last_direction = direction
		play_walk_animation(direction)
	else: 
		play_idle_animation(last_direction)

func play_walk_animation(direction):
	if direction.x > 0:
		$AnimatedSprite2D.play("WalkRight")
	elif direction.x < 0:
		$AnimatedSprite2D.play("WalkLeft")
	elif direction.y > 0:
		$AnimatedSprite2D.play("WalkDown")
	elif direction.y < 0:
		$AnimatedSprite2D.play("WalkUp")

func play_idle_animation(direction):
	if direction.x > 0:
		$AnimatedSprite2D.play("IdleRight")
	elif direction.x < 0:
		$AnimatedSprite2D.play("IdleLeft")
	elif direction.y > 0:
		$AnimatedSprite2D.play("IdleDown")
	elif direction.y < 0:
		$AnimatedSprite2D.play("IdleUp")

#healthpoints
signal hp_changed(current_hp, max_hp)

var max_hp: int = 100
var current_hp: int = max_hp

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	emit_signal("hp_changed", current_hp, max_hp)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)
