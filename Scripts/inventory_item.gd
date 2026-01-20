extends Resource
class_name Inventory

@export var items := {}
@export var max_slots := 10

func add_item(item_name: String, amount := 1):
	if items.has(item_name):
		items[item_name] += amount
	else:
		if items.size() < max_slots:
			items[item_name] = amount

func remove_item(item_name: String, amount := 1):
	if !items.has(item_name):
		return

	items[item_name] -= amount
	if items[item_name] <= 0:
		items.erase(item_name)
