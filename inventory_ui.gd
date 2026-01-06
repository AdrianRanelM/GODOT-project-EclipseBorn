extends Control

const SLOT_COUNT := 24

@onready var grid = $SlotsLayer/MainGrid
@onready var sprite = $SlotsLayer/BigSlot/AnimatedSprite2D
@onready var hp_bar = $SlotsLayer/HealthPointsBar  # adjust path

var slots: Array = []

func connect_player(player: Node) -> void:
	# Connect the player's signal to update the bar
	player.hp_changed.connect(_on_player_hp_changed)

func _on_player_hp_changed(current_hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp

func _ready():
	sprite.play("WalkingInv")
	slots = grid.get_children()   # use the slots already in the scene
	for slot in slots:
		slot.clear()

func update_inventory(inv: Inv) -> void:
	for slot in slots:
		slot.clear()

	for i in range(min(inv.items.size(), slots.size())):
		slots[i].set_item(inv.items[i])
