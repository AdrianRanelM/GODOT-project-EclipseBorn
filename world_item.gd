extends Area2D

@export var item_name: String
@export var amount: int = 1

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.pick_up_item(item_name, amount)
		queue_free()
