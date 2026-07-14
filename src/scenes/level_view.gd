extends Node2D

const TILE_SIZE: float = 80.0

# Color Palette (Neon Cyberpunk)
const COLOR_BG = Color("0a0a16")
const COLOR_GRID_LINE = Color("1e1e3f")
const COLOR_ADMIN = Color("39ff14") # Neon green

# Grid specifications
var grid_width: int = 5
var grid_height: int = 5
var grid_origin: Vector2 = Vector2.ZERO

# Node references
var admin_sprite: ColorRect = null

func setup(model: GridModel) -> void:
	grid_width = model.width
	grid_height = model.height
	recalculate_layout()
	
	# Clear existing visual nodes
	clear_visuals()
	
	# Draw background lines
	queue_redraw()
	
	# Create Admin Node visual
	admin_sprite = create_tile_rect(model.admin_pos, COLOR_ADMIN, Color.WHITE, 2.0)
	# Add a glowing accent center to Admin
	var admin_inner = ColorRect.new()
	admin_inner.color = Color("051a02")
	admin_inner.size = Vector2(TILE_SIZE * 0.4, TILE_SIZE * 0.4)
	admin_inner.position = (admin_sprite.size - admin_inner.size) / 2.0
	admin_sprite.add_child(admin_inner)
	add_child(admin_sprite)

func clear_visuals() -> void:
	if admin_sprite:
		admin_sprite.queue_free()
		admin_sprite = null

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
