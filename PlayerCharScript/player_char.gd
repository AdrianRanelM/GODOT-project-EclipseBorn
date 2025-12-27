extends CharacterBody2D

var max_speed = 100
var last_direction = Vector2(1,0)

#inventory
@onready var animated_inventory = $CanvasLayer/AnimatedInventory

func _input(event):
	if event.is_action_pressed("ToggleInventory"):
		animated_inventory.visible = !animated_inventory.visible

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
