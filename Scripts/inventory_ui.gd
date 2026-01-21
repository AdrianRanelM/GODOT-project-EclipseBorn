extends Control
class_name InventoryUI

const SLOT_COUNT := 24

# No longer export an Inv instance; use the autoload singleton `InvSing`
@export var world_item_scene: PackedScene  # for dropping into world

@onready var grid: GridContainer = $SlotsLayer/MainGrid
@onready var sprite: AnimatedSprite2D = $SlotsLayer/BigSlot/AnimatedSprite2D
@onready var hp_bar: TextureProgressBar = $SlotsLayer/HealthPointsBar
@onready var mp_bar: TextureProgressBar = $SlotsLayer/ManaPointsBar

var slots: Array[ItemSlot] = []
var last_dragged_slot: ItemSlot = null

func connect_player(player: Node) -> void:
	# Connect the player's signal to update the bar
	if player.has_signal("hp_changed"):
		player.hp_changed.connect(Callable(self, "_on_player_hp_changed"))

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

func _on_player_mp_changed(current_mp: int, max_mp: int) -> void:
	mp_bar.max_value = max_mp
	mp_bar.value = current_mp

func _ready():
	sprite.play("WalkingInv")
	slots.clear()
	for child in grid.get_children():
		if child is ItemSlot:
			var slot := child as ItemSlot
			slots.append(slot)
			slot.slot_index = slots.size() - 1
			slot.clear()
			# connect the signal so double‑click works
			slot.slot_used.connect(Callable(self, "_on_slot_used"))
			# optional: track drag start/end if your ItemSlot emits them
			if slot.has_signal("drag_started"):
				slot.drag_started.connect(Callable(self, "_on_slot_drag_started"))
			if slot.has_signal("drag_ended"):
				slot.drag_ended.connect(Callable(self, "_on_slot_drag_ended"))

	# Connect to global PlayerStats signals
	PlayerStats.hp_changed.connect(Callable(self, "_on_player_hp_changed"))
	PlayerStats.mp_changed.connect(Callable(self, "_on_player_mp_changed"))

	# Initialize bars with current values
	_on_player_hp_changed(PlayerStats.current_hp, PlayerStats.max_hp)
	_on_player_mp_changed(PlayerStats.current_mp, PlayerStats.max_mp)

	# Connect to InvSing autoload signals
	if Engine.has_singleton("InvSing"):
		InvSing.slot_changed.connect(Callable(self, "_on_inventory_slot_changed"))
		InvSing.inventory_changed.connect(Callable(self, "_on_inventory_changed"))
		_on_inventory_changed()
	else:
		push_error("InvSing autoload not found. Make sure you added InvSing as an AutoLoad in Project Settings.")

func _on_inventory_changed() -> void:
	for i in range(slots.size()):
		slots[i].set_item(InvSing.get_item(i))

func _on_inventory_slot_changed(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].set_item(InvSing.get_item(slot_index))

func update_inventory(inv_ref) -> void:
	# kept for compatibility with older code that passes an Inv instance
	# but prefer using the autoload InvSing directly
	if inv_ref == null:
		return
	for i in range(slots.size()):
		slots[i].set_item(inv_ref.get_item(i))

func _on_slot_used(slot_index: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	# Explicitly type the item so the analyzer knows what it is
	var item: InvItem = InvSing.get_item(slot_index)
	if item and item.use(player):
		# Example: if item heals, call PlayerStats.heal(amount)
		# if item costs mana, call PlayerStats.spend_mana(cost)
		if item.amount <= 0:
			InvSing.clear_slot(slot_index)
		else:
			# write back changed item (if use modified amount)
			InvSing.set_item(slot_index, item)

# Optional drag handlers (ItemSlot should emit these)
func _on_slot_drag_started(slot: ItemSlot) -> void:
	last_dragged_slot = slot

func _on_slot_drag_ended(slot: ItemSlot) -> void:
	# keep last_dragged_slot until mouse release outside UI
	last_dragged_slot = slot

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		var mouse_global := get_viewport().get_mouse_position()
		var rect := get_global_rect()
		if not rect.has_point(mouse_global) and last_dragged_slot:
			# Drop the item into the world at the mouse world position
			_notify_drop_outside(last_dragged_slot, mouse_global)
			last_dragged_slot = null

func _notify_drop_outside(slot: ItemSlot, mouse_global: Vector2) -> void:
	var slot_index := slot.slot_index
	if slot_index < 0:
		return
	# Explicitly type the item
	var item: InvItem = InvSing.get_item(slot_index)
	if item == null:
		return

	# Convert UI mouse to world position (works if you have a Camera2D)
	var world_pos := mouse_global
	# Explicitly type the camera
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam:
		world_pos = cam.unproject_position(mouse_global)

	# Instantiate world item if scene provided
	if world_item_scene:
		var inst = world_item_scene.instantiate()
		if inst:
			if inst.has_method("setup_from_item"):
				inst.setup_from_item(item)
			# place in current scene root so physics/collisions work
			var root = get_tree().get_current_scene()
			if root:
				root.add_child(inst)
				inst.global_position = world_pos
	# Remove from inventory
	InvSing.clear_slot(slot_index)
