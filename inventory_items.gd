extends Resource

class_name InvItem

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var max_stack: int = 1
@export var description: String = ""

var amount: int = 1

func can_stack_with(other: InvItem) -> bool:
	return other != null and other.id == id and max_stack > 1

func is_full() -> bool:
	return amount >= max_stack

func add_amount(value: int) -> int:
	var space = max_stack - amount
	var added = min(space, value)
	amount += added
	return value - added
