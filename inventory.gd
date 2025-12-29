extends Resource
class_name Inv

@export var items: Array[InvItem] = []

func add_item(new_item: InvItem) -> void:
	if new_item == null:
		return

	# Try stacking first
	for item in items:
		if item == null:
			continue

		if item.can_stack_with(new_item) and not item.is_full():
			new_item.amount = item.add_amount(new_item.amount)
			if new_item.amount <= 0:
				return

	# Add as new item
	items.append(new_item)
