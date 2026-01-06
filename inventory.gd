extends Resource
class_name Inv

@export var items: Array[InvItem] = []
@export var max_slots: int = 24   # or 24, depending on your design

func is_full() -> bool:
	return items.size() >= max_slots

func add_item(new_item: InvItem) -> bool:
	if new_item == null:
		return false

	# Try stacking first
	for item in items:
		if item == null:
			continue
		if item.can_stack_with(new_item) and not item.is_full():
			new_item.amount = item.add_amount(new_item.amount)
			if new_item.amount <= 0:
				return true  # stacked successfully

	# If no stack space, check slots
	if is_full():
		return false  # inventory full, reject pickup

	# Add as new item
	items.append(new_item)
	return true
