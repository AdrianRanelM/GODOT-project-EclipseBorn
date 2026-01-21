# res://scripts/InventorySingleton.gd
extends Node
class_name InventorySingleton

@export var inv_resource: Inv = null

signal slot_changed(slot_index: int)
signal inventory_changed()

func _ready() -> void:
	if inv_resource == null:
		inv_resource = Inv.new()  # uses your Inv._init to size slots

# Accessors and mutators
func get_item(index: int):
	return inv_resource.get_item(index)

func set_item(index: int, item):
	inv_resource.set_item(index, item)
	emit_signal("slot_changed", index)
	emit_signal("inventory_changed")

func clear_slot(index: int) -> void:
	inv_resource.clear_slot(index)
	emit_signal("slot_changed", index)
	emit_signal("inventory_changed")

func add_item(item) -> bool:
	var ok = inv_resource.add_item(item)
	if ok:
		emit_signal("inventory_changed")
	return ok

func swap_slots(a: int, b: int) -> void:
	inv_resource.swap_slots(a, b)
	emit_signal("inventory_changed")
