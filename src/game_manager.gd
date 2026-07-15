extends Node

const GridModelClass = preload("res://src/core/grid_model.gd")
const LevelDataClass = preload("res://src/core/level_data.gd")

@onready var level_view: Node2D = $LevelView

var model: GridModel = null
var current_level_data: LevelData = null

func _ready() -> void:
	# Instantiate GridModel
	model = GridModelClass.new()
	
	# Load level config
	current_level_data = load("res://level_1.tres") as LevelData
	
	# Initialize the logic model
	model.initialize(current_level_data)
	
	# Initialize visual view
	level_view.setup(model)
	
	# Connect view input signal
	level_view.move_requested.connect(_on_move_requested)

func _on_move_requested(direction: Vector2i) -> void:
	var report = model.move(direction)
	if report["success"]:
		print("Player moved to: ", model.admin_pos)
		# Update visuals instantly
		level_view.snap_to_state(model)
