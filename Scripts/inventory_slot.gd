extends Control
class_name ItemSlot

signal slot_used(slot_index: int)

@export var slot_index: int = 0
var item: InvItem = null

@onready var icon_rect: TextureRect = $Icon
@onready var amount_label: Label = $Amount

# Manual double‑click detection
var last_click_time: float = 0.0
const DOUBLE_CLICK_THRESHOLD := 0.3  # seconds

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP   # ensure we receive mouse input

func set_item(new_item: InvItem) -> void:
	item = new_item
	if item:
		icon_rect.texture = item.icon
		amount_label.text = str(item.amount) if item.amount > 1 else ""
		modulate = Color.WHITE
	else:
		icon_rect.texture = null
		amount_label.text = ""
		modulate = Color(1,1,1,0.3)

func clear() -> void:
	set_item(null)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var now := Time.get_ticks_msec() / 1000.0
		if now - last_click_time <= DOUBLE_CLICK_THRESHOLD:
			# Double‑click detected
			if item and item.amount > 0:
				emit_signal("slot_used", slot_index)
		last_click_time = now

# Tooltip shows description when hovered
func _get_tooltip(_at_position: Vector2) -> String:
	if item == null:
		return ""
	return "%s\n%s" % [item.display_name, item.description]
