class_name GridModel
extends RefCounted

# Grid dimensions
var width: int = 5
var height: int = 5

# Cycles / Steps
var max_cycles: int = 15
var cycles_remaining: int = 15

# Entity positions
var admin_pos: Vector2i = Vector2i.ZERO
var zombie_positions: Array = []

# Static coordinates
var wall_positions: Array = []
var gc_positions: Array = []
var emp_positions: Array = []
var exit_pos: Vector2i = Vector2i(4, 4)

# Game states
var game_over: bool = false
var victory: bool = false
var exit_unlocked: bool = false
var emp_active_turns: int = 0

# Initialize from LevelData
func initialize(level_data: Resource) -> void:
	width = level_data.width
	height = level_data.height
	max_cycles = level_data.max_cycles
	cycles_remaining = level_data.max_cycles
	
	admin_pos = level_data.admin_start_pos
	zombie_positions = level_data.zombie_start_positions.duplicate()
	wall_positions = level_data.wall_positions.duplicate()
	gc_positions = level_data.gc_tile_positions.duplicate()
	emp_positions = level_data.emp_start_positions.duplicate()
	exit_pos = level_data.exit_position
	
	game_over = false
	victory = false
	exit_unlocked = zombie_positions.is_empty()
	emp_active_turns = 0

# Attempt to move. Returns a report of what occurred.
func move(direction: Vector2i) -> Dictionary:
	var report = {
		"success": false,
		"admin_old": admin_pos,
		"admin_new": admin_pos,
		"zombies_old": zombie_positions.duplicate(),
		"zombies_new": zombie_positions.duplicate(),
		"deleted_zombies": [],
		"game_over": game_over,
		"victory": victory,
		"exit_unlocked": exit_unlocked,
		"collected_emp": Vector2i(-1, -1),
		"emp_active_turns": emp_active_turns
	}
	
	if game_over or victory or cycles_remaining <= 0:
		return report
		
	# 1. Check Admin move validity
	var proposed_admin_pos = admin_pos + direction
	if not is_in_bounds(proposed_admin_pos) or proposed_admin_pos in wall_positions:
		# Blocked - abort turn entirely (no cost, zombies do not move)
		return report
		
	# Admin move is valid
	report["success"] = true
	var old_admin_pos = admin_pos
	admin_pos = proposed_admin_pos
	cycles_remaining -= 1
	report["admin_new"] = admin_pos
	
	# Check for EMP collection
	var collected_emp = Vector2i(-1, -1)
	if admin_pos in emp_positions:
		collected_emp = admin_pos
		emp_positions.erase(admin_pos)
		emp_active_turns = 3
	report["collected_emp"] = collected_emp
	
	# 2. Move Zombies (mirrored direction unless EMP is active)
	var old_zombies = zombie_positions.duplicate()
	var new_zombies: Array = []
	
	if emp_active_turns > 0:
		new_zombies = old_zombies.duplicate()
		emp_active_turns -= 1
	else:
		for i in range(old_zombies.size()):
			var proposed_zombie_pos = old_zombies[i] - direction # Mirrored
			if is_in_bounds(proposed_zombie_pos) and not proposed_zombie_pos in wall_positions:
				new_zombies.append(proposed_zombie_pos)
			else:
				new_zombies.append(old_zombies[i]) # Remain in place if blocked
			
	zombie_positions = new_zombies
	report["zombies_new"] = zombie_positions.duplicate()
	report["emp_active_turns"] = emp_active_turns
	
	# 3. Check for Collisions (Same-Cell & Swapping)
	# Same cell collision check
	for new_z_pos in zombie_positions:
		if new_z_pos == admin_pos:
			game_over = true
			break
			
	# Swapping collision check
	if not game_over:
		for i in range(zombie_positions.size()):
			if admin_pos == old_zombies[i] and zombie_positions[i] == old_admin_pos:
				game_over = true
				break
				
	# 4. Check Garbage Collection Deletion (if not game over)
	var surviving_zombies: Array = []
	var deleted: Array = []
	
	if not game_over:
		for z_pos in zombie_positions:
			if z_pos in gc_positions:
				deleted.append(z_pos)
			else:
				surviving_zombies.append(z_pos)
		zombie_positions = surviving_zombies
		report["deleted_zombies"] = deleted
		
	# Update unlock state
	exit_unlocked = zombie_positions.is_empty()
	report["exit_unlocked"] = exit_unlocked
	
	# 5. Check Win/Loss conditions
	if not game_over:
		if admin_pos == exit_pos and exit_unlocked:
			victory = true
		elif cycles_remaining <= 0 and not victory:
			game_over = true
			
	report["game_over"] = game_over
	report["victory"] = victory
	
	return report

# Utility to check coordinates
func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

# Serialize state for history management
func serialize_state() -> Dictionary:
	return {
		"cycles_remaining": cycles_remaining,
		"admin_pos": admin_pos,
		"zombie_positions": zombie_positions.duplicate(),
		"game_over": game_over,
		"victory": victory,
		"exit_unlocked": exit_unlocked,
		"emp_positions": emp_positions.duplicate(),
		"emp_active_turns": emp_active_turns
	}

# Deserialize state from history management
func deserialize_state(state: Dictionary) -> void:
	cycles_remaining = state["cycles_remaining"]
	admin_pos = state["admin_pos"]
	zombie_positions = state["zombie_positions"].duplicate()
	game_over = state["game_over"]
	victory = state["victory"]
	exit_unlocked = state["exit_unlocked"]
	emp_positions = state["emp_positions"].duplicate()
	emp_active_turns = state["emp_active_turns"]
