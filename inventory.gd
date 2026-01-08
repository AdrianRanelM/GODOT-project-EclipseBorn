extends Resource
class_name Inv

@export var max_slots: int = 24
# Explicit slot mapping: each index corresponds to a UI slot
var slots: Array[InvItem] = []

func _init():
	# Initialize with empty slots
	slots.resize(max_slots)

func is_full() -> bool:
	# Full if no empty slot AND no stack room
	for i in range(max_slots):
		var item = slots[i]
		if item == null:
			return false
		if not item.is_full():
			return false
	return true

func get_item(slot_index: int) -> InvItem:
	if slot_index < 0 or slot_index >= max_slots:
		return null
	return slots[slot_index]

func set_item(slot_index: int, item: InvItem) -> void:
	if slot_index < 0 or slot_index >= max_slots:
		return
	slots[slot_index] = item

func clear_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= max_slots:
		return
	slots[slot_index] = null

func add_item(new_item: InvItem) -> bool:
	if new_item == null:
		return false

	# Try stacking first
	for i in range(max_slots):
		var item = slots[i]
		if item and item.can_stack_with(new_item) and not item.is_full():
			new_item.amount = item.add_amount(new_item.amount)
			if new_item.amount <= 0:
				return true  # fully stacked

	# Find empty slot
	for i in range(max_slots):
		if slots[i] == null:
			slots[i] = new_item
			return true

	return false  # no slot and no stacking room

func swap_slots(a: int, b: int) -> void:
	if a < 0 or a >= max_slots or b < 0 or b >= max_slots:
		return
	var temp = slots[a]
	slots[a] = slots[b]
	slots[b] = temp
