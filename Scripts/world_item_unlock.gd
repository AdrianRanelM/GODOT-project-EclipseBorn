extends Area2D
class_name WorldItemUnlock

@export var item_data: InvItem
@export var amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D

var player_in_range: CharacterBody2D = null

func _ready():
	if item_data and item_data.icon:
		sprite.texture = item_data.icon

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = body

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null

func _input(event):
	if player_in_range and event.is_action_pressed("PickItemUp"):
		pick_up(player_in_range)

func pick_up(player: CharacterBody2D):
	if player.has_method("unlock_inventory"):
		player.soulbelt()
		player.unlock_inventory()
	queue_free()   # remove from world

func get_item() -> InvItem:
	var item := item_data.duplicate(true) as InvItem
	item.amount = amount
	return item
