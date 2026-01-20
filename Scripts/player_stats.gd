extends Node

signal hp_changed(current_hp, max_hp)
signal mp_changed(current_mp, max_mp)

var max_hp: int = 100
var current_hp: int = max_hp
var max_mp: int = 100
var current_mp: int = max_mp

func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)
	emit_signal("hp_changed", current_hp, max_hp)

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)

func spend_mana(cost: int) -> void:
	current_mp = max(current_mp - cost, 0)
	emit_signal("mp_changed", current_mp, max_mp)
