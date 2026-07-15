class_name HistoryManager
extends RefCounted

var undo_stack: Array = []
var redo_stack: Array = []

func push_state(state: Dictionary) -> void:
	# Deep duplicate the state to prevent reference mutations
	undo_stack.append(state.duplicate(true))
	redo_stack.clear()

func undo(current_state: Dictionary) -> Dictionary:
	if not can_undo():
		return {}
	
	# Push current state to redo stack
	redo_stack.append(current_state.duplicate(true))
	# Pop and return previous state
	return undo_stack.pop_back()

func redo(current_state: Dictionary) -> Dictionary:
	if not can_redo():
		return {}
	
	# Push current state to undo stack
	undo_stack.append(current_state.duplicate(true))
	# Pop and return next state
	return redo_stack.pop_back()

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()

func can_undo() -> bool:
	return not undo_stack.is_empty()

func can_redo() -> bool:
	return not redo_stack.is_empty()
