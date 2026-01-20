extends CharacterBody2D

@export var max_hp := 100
var hp := max_hp

@export var inventory: Inventory

func _ready():
	hp = max_hp

func take_damage(amount: int):
	hp = clamp(hp - amount, 0, max_hp)

func heal(amount: int):
	hp = clamp(hp + amount, 0, max_hp)
