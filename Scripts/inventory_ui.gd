extends Control
class_name InventoryUI

const SLOT_COUNT := 24

@export var inv: Inv
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
		player.hp_changed.connect(_on_player_hp_changed)

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
			# 👇 connect the signal so double‑click works
			slot.slot_used.connect(_on_slot_used)
	# Connect to global PlayerStats signals
	PlayerStats.hp_changed.connect(_on_player_hp_changed)
	PlayerStats.mp_changed.connect(_on_player_mp_changed)

	# Initialize bars with current values
	_on_player_hp_changed(PlayerStats.current_hp, PlayerStats.max_hp)
	_on_player_mp_changed(PlayerStats.current_mp, PlayerStats.max_mp)

	if inv:
		update_inventory(inv)

func update_inventory(inv_ref: Inv) -> void:
	inv = inv_ref
	for i in range(slots.size()):
		slots[i].set_item(inv.get_item(i))

func _on_slot_used(slot_index: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var item := inv.get_item(slot_index)
	if item and item.use(player):
		# Example: if item heals, call PlayerStats.heal(amount)
		# if item costs mana, call PlayerStats.spend_mana(cost)
		if item.amount <= 0:
			inv.clear_slot(slot_index)
		update_inventory(inv)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		var mouse_global := get_viewport().get_mouse_position()
		var rect := get_global_rect()
		if not rect.has_point(mouse_global) and last_dragged_slot:
			last_dragged_slot.notify_drop_outside(mouse_global)
			last_dragged_slot = null
