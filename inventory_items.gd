# InvItem.gd
extends Resource
class_name InvItem

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export var max_stack: int = 1
@export var description: String = ""
@export var heal_amount: int = 0

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

func use(target) -> bool:
	if heal_amount <= 0 or amount <= 0 or target == null:
		return false
	target.heal(heal_amount)
	amount -= 1
	return true
