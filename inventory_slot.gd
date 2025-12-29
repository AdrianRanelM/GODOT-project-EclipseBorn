extends TextureButton

@onready var item_visual: TextureRect = $ItemDisplay
var current_item: InvItem = null

func set_item(new_item: InvItem) -> void:
	current_item = new_item
	if new_item == null:
		clear()
		return

	# Show icon
	item_visual.visible = true
	item_visual.texture = new_item.icon   # <-- use icon, not text

func clear() -> void:
	current_item = null
	item_visual.visible = false
	item_visual.texture = null

# Correct signature in Godot 4
func _get_tooltip(_at_position: Vector2) -> String:
	if current_item == null:
		return ""
	return "%s\n%s" % [current_item.display_name, current_item.description]
