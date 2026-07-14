class_name LevelData
extends Resource

@export var width: int = 5
@export var height: int = 5
@export var max_cycles: int = 15

@export var admin_start_pos: Vector2i = Vector2i.ZERO
@export var zombie_start_positions: Array = []
@export var wall_positions: Array = []
@export var gc_tile_positions: Array = []
@export var emp_start_positions: Array = []
@export var exit_position: Vector2i = Vector2i(4, 4)
