extends Node2D

const TILE_SIZE: float = 80.0

# Color Palette (Neon Cyberpunk)
const COLOR_BG = Color("0a0a16")
const COLOR_GRID_LINE = Color("1e1e3f")
const COLOR_WALL = Color("2e2e4f")
const COLOR_WALL_BORDER = Color("f07178") # Orange neon accent
const COLOR_GC = Color("2b1b54") # Dark purple
const COLOR_GC_BORDER = Color("00f0ff") # Neon cyan accent
const COLOR_EXIT_LOCKED = Color("3a1c3f")
const COLOR_EXIT_UNLOCKED = Color("ff007f") # Glowing magenta
const COLOR_ADMIN = Color("39ff14") # Neon green
const COLOR_ZOMBIE = Color("ff3131") # Neon red
const COLOR_EMP = Color("b5a642") # Neon gold/yellow
const COLOR_EMP_BORDER = Color("ffff33") # Neon gold border
const COLOR_ZOMBIE_FROZEN = Color("33ccff") # Neon blue freeze

# Grid specifications
var grid_width: int = 5
var grid_height: int = 5
var grid_origin: Vector2 = Vector2.ZERO

# Node references
var admin_sprite: ColorRect = null
var exit_sprite: ColorRect = null
var wall_nodes: Array[ColorRect] = []
var gc_nodes: Array[ColorRect] = []
var zombie_nodes: Dictionary = {} # Maps logical Vector2i -> ColorRect
var emp_nodes: Dictionary = {} # Maps logical Vector2i -> ColorRect

func setup(model: GridModel) -> void:
	grid_width = model.width
	grid_height = model.height
	recalculate_layout()
	
	# Clear existing visual nodes
	clear_visuals()
	
	# Draw background lines
	queue_redraw()
	
	# 1. Create static Firewall visual nodes
	for wall in model.wall_positions:
		var rect = create_tile_rect(wall, COLOR_WALL, COLOR_WALL_BORDER, 4.0)
		add_child(rect)
		wall_nodes.append(rect)
		
	# 2. Create static Garbage Collection visual nodes
	for gc in model.gc_positions:
		var rect = create_tile_rect(gc, COLOR_GC, COLOR_GC_BORDER, 3.0)
		add_child(rect)
		gc_nodes.append(rect)
		
	# 3. Create Exit Portal node
	exit_sprite = create_tile_rect(model.exit_pos, COLOR_EXIT_LOCKED, COLOR_GRID_LINE, 2.0)
	add_child(exit_sprite)
	update_exit_portal(model.exit_unlocked)
	
	# 4. Create Admin Node visual
	admin_sprite = create_tile_rect(model.admin_pos, COLOR_ADMIN, Color.WHITE, 2.0)
	# Add a glowing accent center to Admin
	var admin_inner = ColorRect.new()
	admin_inner.color = Color("051a02")
	admin_inner.size = Vector2(TILE_SIZE * 0.4, TILE_SIZE * 0.4)
	admin_inner.position = (admin_sprite.size - admin_inner.size) / 2.0
	admin_sprite.add_child(admin_inner)
	add_child(admin_sprite)
	
	# 4.5. Create EMP Node visuals
	for emp in model.emp_positions:
		create_emp_visual(emp)
		
	# 5. Create Zombie Nodes visuals
	for z_pos in model.zombie_positions:
		create_zombie_visual(z_pos)

func clear_visuals() -> void:
	if admin_sprite:
		admin_sprite.queue_free()
		admin_sprite = null
	if exit_sprite:
		exit_sprite.queue_free()
		exit_sprite = null
	for node in wall_nodes:
		node.queue_free()
	wall_nodes.clear()
	for node in gc_nodes:
		node.queue_free()
	gc_nodes.clear()
	for node in zombie_nodes.values():
		node.queue_free()
	zombie_nodes.clear()
	for node in emp_nodes.values():
		node.queue_free()
	emp_nodes.clear()

func create_emp_visual(grid_pos: Vector2i) -> void:
	var rect = create_tile_rect(grid_pos, COLOR_EMP, COLOR_EMP_BORDER, 2.0)
	var inner = ColorRect.new()
	inner.color = Color("252202")
	inner.size = Vector2(TILE_SIZE * 0.3, TILE_SIZE * 0.3)
	inner.position = (rect.size - inner.size) / 2.0
	rect.add_child(inner)
	add_child(rect)
	emp_nodes[grid_pos] = rect

func create_zombie_visual(grid_pos: Vector2i) -> void:
	var rect = create_tile_rect(grid_pos, COLOR_ZOMBIE, Color.WHITE, 2.0)
	# Add an inner danger square
	var inner = ColorRect.new()
	inner.color = Color("230000")
	inner.size = Vector2(TILE_SIZE * 0.4, TILE_SIZE * 0.4)
	inner.position = (rect.size - inner.size) / 2.0
	rect.add_child(inner)
	add_child(rect)
	zombie_nodes[grid_pos] = rect

func update_exit_portal(unlocked: bool) -> void:
	if exit_sprite:
		var fill = exit_sprite.get_child(0) as ColorRect
		if fill:
			fill.color = COLOR_EXIT_UNLOCKED if unlocked else COLOR_EXIT_LOCKED
		exit_sprite.color = COLOR_EXIT_UNLOCKED if unlocked else COLOR_GRID_LINE

func create_tile_rect(grid_pos: Vector2i, fill_color: Color, border_color: Color, border_width: float) -> ColorRect:
	var rect = ColorRect.new()
	rect.size = Vector2(TILE_SIZE - 4, TILE_SIZE - 4) # Padding of 2px on each side
	rect.position = grid_to_pixel(grid_pos)
	rect.color = border_color
	
	# Inner fill
	var fill = ColorRect.new()
	fill.size = rect.size - Vector2(border_width * 2, border_width * 2)
	fill.position = Vector2(border_width, border_width)
	fill.color = fill_color
	rect.add_child(fill)
	
	return rect

func recalculate_layout() -> void:
	var viewport_size = get_viewport_rect().size
	var grid_total_width = grid_width * TILE_SIZE
	var grid_total_height = grid_height * TILE_SIZE
	# Calculate origin to center the grid
	grid_origin = (viewport_size - Vector2(grid_total_width, grid_total_height)) / 2.0

func grid_to_pixel(grid_pos: Vector2i) -> Vector2:
	return grid_origin + Vector2(grid_pos.x * TILE_SIZE + 2, grid_pos.y * TILE_SIZE + 2)

func _draw() -> void:
	# Draw main grid container background
	var grid_total_width = grid_width * TILE_SIZE
	var grid_total_height = grid_height * TILE_SIZE
	
	# Solid dark background for the matrix area
	draw_rect(Rect2(grid_origin, Vector2(grid_total_width, grid_total_height)), COLOR_BG, true)
	
	# Draw cells and grid lines
	for x in range(grid_width + 1):
		var start = grid_origin + Vector2(x * TILE_SIZE, 0)
		var end = grid_origin + Vector2(x * TILE_SIZE, grid_total_height)
		draw_line(start, end, COLOR_GRID_LINE, 2.0)
		
	for y in range(grid_height + 1):
		var start = grid_origin + Vector2(0, y * TILE_SIZE)
		var end = grid_origin + Vector2(grid_total_width, y * TILE_SIZE)
		draw_line(start, end, COLOR_GRID_LINE, 2.0)
