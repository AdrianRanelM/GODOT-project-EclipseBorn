# ConversationStack.gd
# Simple stack for dialogue frames. Each frame is a Dictionary:
# { "speaker": String, "text": String, "meta": Variant }
extends RefCounted
class_name ConversationStack

var _stack: Array = []

func push(frame: Dictionary) -> void:
	_stack.append(frame)

func pop() -> Dictionary:
	if _stack.is_empty():
		return {}
	return _stack.pop_back()

func peek() -> Dictionary:
	if _stack.is_empty():
		return {}
	return _stack[_stack.size() - 1]

func clear() -> void:
	_stack.clear()

func is_empty() -> bool:
	return _stack.is_empty()

func size() -> int:
	return _stack.size()
