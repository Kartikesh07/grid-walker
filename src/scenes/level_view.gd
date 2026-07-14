extends Node2D

const TILE_SIZE: float = 80.0

# Color Palette (Neon Cyberpunk)
const COLOR_BG = Color("0a0a16")
const COLOR_GRID_LINE = Color("1e1e3f")

# Grid specifications
var grid_width: int = 5
var grid_height: int = 5
var grid_origin: Vector2 = Vector2.ZERO

func setup(model: GridModel) -> void:
	grid_width = model.width
	grid_height = model.height
	recalculate_layout()
	queue_redraw()

func recalculate_layout() -> void:
	var viewport_size = get_viewport_rect().size
	var grid_total_width = grid_width * TILE_SIZE
	var grid_total_height = grid_height * TILE_SIZE
	# Calculate origin to center the grid
	grid_origin = (viewport_size - Vector2(grid_total_width, grid_total_height)) / 2.0

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
