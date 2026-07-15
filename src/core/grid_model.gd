class_name GridModel
extends RefCounted

# Grid dimensions
var width: int = 5
var height: int = 5

# Entity positions
var admin_pos: Vector2i = Vector2i.ZERO
var zombie_positions: Array = []

# Static coordinates (stored for the view to draw)
var wall_positions: Array = []
var gc_positions: Array = []
var emp_positions: Array = []
var exit_pos: Vector2i = Vector2i.ZERO

# Game states
var exit_unlocked: bool = false
var victory: bool = false
var game_over: bool = false

# Initialize from LevelData (Loading all layouts)
func initialize(level_data: Resource) -> void:
	width = level_data.width
	height = level_data.height
	admin_pos = level_data.admin_start_pos
	zombie_positions = level_data.zombie_start_positions.duplicate()
	wall_positions = level_data.wall_positions.duplicate()
	gc_positions = level_data.gc_tile_positions.duplicate()
	emp_positions = level_data.emp_start_positions.duplicate()
	exit_pos = level_data.exit_position
	
	exit_unlocked = zombie_positions.is_empty()
	victory = false
	game_over = false

# Move turn: moves player and moves all zombies (blocked by walls/edges only)
func move(direction: Vector2i) -> Dictionary:
	var report = {
		"success": false,
		"admin_old": admin_pos,
		"admin_new": admin_pos,
		"zombies_old": zombie_positions.duplicate(),
		"zombies_new": zombie_positions.duplicate(),
		"victory": victory,
		"game_over": game_over,
		"exit_unlocked": exit_unlocked
	}
	
	# If game is already won or lost, block any further moves
	if victory or game_over:
		return report
	
	# 1. Validate Player proposed move (blocked by walls or grid edges)
	var proposed_admin_pos = admin_pos + direction
	if not is_in_bounds(proposed_admin_pos) or proposed_admin_pos in wall_positions:
		return report
		
	# Player move is valid
	report["success"] = true
	var old_admin_pos = admin_pos
	admin_pos = proposed_admin_pos
	report["admin_new"] = admin_pos
	
	# 2. Move Zombies in mirrored direction (preventing overlaps)
	var old_zombies = zombie_positions.duplicate()
	var new_zombies: Array = []
	
	# Sort zombies so leading ones in the direction of movement (-direction) are processed first
	var z_move = -direction
	var sorted_zombies = old_zombies.duplicate()
	sorted_zombies.sort_custom(func(a: Vector2i, b: Vector2i):
		var score_a = a.x * z_move.x + a.y * z_move.y
		var score_b = b.x * z_move.x + b.y * z_move.y
		return score_a > score_b # Descending order
	)
	
	var remaining = sorted_zombies.duplicate()
	
	for z in sorted_zombies:
		remaining.erase(z)
		var proposed_z_pos = z - direction # Mirrored
		
		var can_move = (
			is_in_bounds(proposed_z_pos) and
			not proposed_z_pos in wall_positions and
			not proposed_z_pos in new_zombies and
			not proposed_z_pos in remaining
		)
		
		if can_move:
			new_zombies.append(proposed_z_pos)
		else:
			new_zombies.append(z) # Stay in place if blocked
			
	zombie_positions = new_zombies
	
	# 3. Check for Garbage Collection Deletions
	var surviving_zombies: Array = []
	for z_pos in zombie_positions:
		if z_pos in gc_positions:
			print("Zombie deleted at GC tile: ", z_pos)
		else:
			surviving_zombies.append(z_pos)
	zombie_positions = surviving_zombies
	
	# 3.5. Check for Breach/Failure collisions (Same-cell & Swapping)
	# Check same-cell collision
	for z_pos in zombie_positions:
		if z_pos == admin_pos:
			game_over = true
			print("Breach detected: Same cell collision!")
			break
			
	# Check swapping collision (crossing paths in opposite directions)
	if not game_over:
		for i in range(zombie_positions.size()):
			# Did the zombie and player swap tiles this turn?
			if admin_pos == old_zombies[i] and zombie_positions[i] == old_admin_pos:
				game_over = true
				print("Breach detected: Swapping collision!")
				break
	
	# 4. Check Exit Portal unlock state
	exit_unlocked = zombie_positions.is_empty()
	
	# 5. Check Victory conditions (Stepping on unlocked exit, if not breached)
	if not game_over and admin_pos == exit_pos and exit_unlocked:
		victory = true
		print("Victory achieved in model!")
		
	report["zombies_new"] = zombie_positions.duplicate()
	report["exit_unlocked"] = exit_unlocked
	report["victory"] = victory
	report["game_over"] = game_over
	
	return report

# Utility to check coordinates boundary
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

# Simple serialization for history management
func serialize_state() -> Dictionary:
	return {
		"admin_pos": admin_pos,
		"zombie_positions": zombie_positions.duplicate(),
		"emp_positions": emp_positions.duplicate(),
		"exit_unlocked": exit_unlocked,
		"victory": victory,
		"game_over": game_over
	}

# Simple deserialization for history management
func deserialize_state(state: Dictionary) -> void:
	admin_pos = state["admin_pos"]
	zombie_positions = state["zombie_positions"].duplicate()
	emp_positions = state["emp_positions"].duplicate()
	exit_unlocked = state["exit_unlocked"]
	victory = state["victory"]
	game_over = state["game_over"]
