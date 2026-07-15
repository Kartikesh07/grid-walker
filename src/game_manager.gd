extends Node

const GridModelClass = preload("res://src/core/grid_model.gd")
const LevelDataClass = preload("res://src/core/level_data.gd")

@onready var level_view: Node2D = $LevelView

var model: GridModel = null
var current_level_data: LevelData = null
var history: HistoryManager = null

func _ready() -> void:
	# Instantiate GridModel and HistoryManager
	model = GridModelClass.new()
	history = HistoryManager.new()
	
	# Load level config
	current_level_data = load("res://level_1.tres") as LevelData
	
	# Initialize the logic model
	model.initialize(current_level_data)
	
	# Initialize visual view
	level_view.setup(model)
	
	# Connect view input signals
	level_view.move_requested.connect(_on_move_requested)
	level_view.undo_requested.connect(_on_undo_requested)
	level_view.redo_requested.connect(_on_redo_requested)

func _on_move_requested(direction: Vector2i) -> void:
	# Capture the pre-move state and save it to the history stack
	var state_before_move = model.serialize_state()
	
	var report = model.move(direction)
	if report["success"]:
		# Push state to history only if the move was successful
		history.push_state(state_before_move)
		print("Player moved to: ", model.admin_pos)
		# Update visuals instantly
		level_view.snap_to_state(model)
		
		# Check for victory or game over conditions
		if model.victory:
			print("VICTORY! Level completed successfully!")
			_restart_level()
		elif model.game_over:
			print("BREACHED! Game Over!")
			_restart_level()

func _on_undo_requested() -> void:
	if history.can_undo():
		# Capture current state to push to the redo stack, and retrieve previous state
		var current_state = model.serialize_state()
		var previous_state = history.undo(current_state)
		
		# Apply previous state
		model.deserialize_state(previous_state)
		level_view.snap_to_state(model)
		print("Undo executed. Player back at: ", model.admin_pos)
	else:
		print("Undo stack empty.")

func _on_redo_requested() -> void:
	if history.can_redo():
		# Capture current state to push to the undo stack, and retrieve next state
		var current_state = model.serialize_state()
		var next_state = history.redo(current_state)
		
		# Apply next state
		model.deserialize_state(next_state)
		level_view.snap_to_state(model)
		print("Redo executed. Player forward at: ", model.admin_pos)
	else:
		print("Redo stack empty.")

func _restart_level() -> void:
	# Reset history and reload level model and view layouts
	history.clear()
	model.initialize(current_level_data)
	level_view.setup(model)
