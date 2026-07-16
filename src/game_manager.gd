extends Node

const GridModelClass = preload("res://src/core/grid_model.gd")
const LevelDataClass = preload("res://src/core/level_data.gd")

# Level files registry
const LEVELS: Array[String] = [
	"res://level_1.tres",
	"res://level_2.tres",
	"res://level_3.tres"
]
var current_level_index: int = 0

# Audio assets preloads
const STREAM_BG_MUSIC = preload("res://Music/BackgrounMusic2.mp3")
const STREAM_BUTTON_CLICK = preload("res://Music/ButtonClick.wav")
const STREAM_EMP = preload("res://Music/EMP.wav")
const STREAM_FAILURE = preload("res://Music/Faillure.wav")
const STREAM_MOVE = preload("res://Music/Move2.wav")
const STREAM_VICTORY = preload("res://Music/Victory.wav")

# Expose volume settings to Godot Inspector for easy customization
@export var sfx_volume_db: float = -12.0 # Default SFX volume (softer)
@export var bgm_volume_db: float = -6.0  # Default BGM volume (audible)

@onready var level_view: Node2D = $LevelView
@onready var hud: CanvasLayer = $HUD

var model: GridModel = null
var current_level_data: LevelData = null
var history: HistoryManager = null

# Programmatic music player
var bg_music_player: AudioStreamPlayer = null

func _ready() -> void:
	# Instantiate GridModel and HistoryManager
	model = GridModelClass.new()
	history = HistoryManager.new()
	
	# Load level config dynamically based on current index
	current_level_data = load(LEVELS[current_level_index]) as LevelData
	
	# Initialize the logic model
	model.initialize(current_level_data)
	
	# Initialize visual view
	level_view.setup(model)
	
	# Connect view input signals
	level_view.move_requested.connect(_on_move_requested)
	level_view.undo_requested.connect(_on_undo_requested)
	level_view.redo_requested.connect(_on_redo_requested)
	
	# Connect HUD action requests
	hud.restart_requested.connect(_on_hud_restart)
	hud.undo_requested.connect(_on_hud_undo)
	hud.redo_requested.connect(_on_hud_redo)
	hud.home_requested.connect(_on_hud_home)
	hud.next_level_requested.connect(_on_hud_next_level)
	
	# Initialize HUD button and cycle states
	_update_hud_states()
	
	# Start looping background music
	_setup_background_music()

func _on_move_requested(direction: Vector2i) -> void:
	# Capture the pre-move state and save it to the history stack
	var state_before_move = model.serialize_state()
	
	# Record EMP presence before movement to detect collection
	var had_emp_before = model.admin_pos in model.emp_positions
	
	var report = model.move(direction)
	if report["success"]:
		# Push state to history only if the move was successful
		history.push_state(state_before_move)
		print("Player moved to: ", model.admin_pos)
		
		# Update visuals with slide animations matching player move direction
		level_view.snap_to_state(model, direction)
		
		# Show HUD popups for win/loss instead of instantly resetting
		if model.victory:
			print("VICTORY! Level completed successfully!")
			play_sfx(STREAM_VICTORY)
			hud.show_victory()
		elif model.game_over:
			print("BREACHED! Game Over!")
			play_sfx(STREAM_FAILURE)
			hud.show_breach()
		else:
			# Play movement sound
			play_sfx(STREAM_MOVE)
			# Play EMP sound if collected during this step
			var has_emp_now = model.admin_pos in model.emp_positions
			# If the EMP is no longer in emp_positions, it was collected this turn
			if state_before_move["emp_positions"].has(model.admin_pos) and not model.emp_positions.has(model.admin_pos):
				play_sfx(STREAM_EMP)
				
			_update_hud_states()

func _on_undo_requested() -> void:
	if history.can_undo():
		play_sfx(STREAM_BUTTON_CLICK)
		# Capture current state to push to the redo stack, and retrieve previous state
		var current_state = model.serialize_state()
		var previous_state = history.undo(current_state)
		
		# Apply previous state
		model.deserialize_state(previous_state)
		level_view.snap_to_state(model)
		hud.hide_popup() # Hide popup since we've rewound to safety
		_update_hud_states()
		print("Undo executed. Player back at: ", model.admin_pos)
	else:
		print("Undo stack empty.")

func _on_redo_requested() -> void:
	if history.can_redo():
		play_sfx(STREAM_BUTTON_CLICK)
		# Capture current state to push to the undo stack, and retrieve next state
		var current_state = model.serialize_state()
		var next_state = history.redo(current_state)
		
		# Apply next state
		model.deserialize_state(next_state)
		level_view.snap_to_state(model)
		
		# Re-evaluate popup state based on redo state
		if model.victory:
			play_sfx(STREAM_VICTORY)
			hud.show_victory()
		elif model.game_over:
			play_sfx(STREAM_FAILURE)
			hud.show_breach()
		else:
			hud.hide_popup()
			_update_hud_states()
			
		print("Redo executed. Player forward at: ", model.admin_pos)
	else:
		print("Redo stack empty.")

func _on_hud_restart() -> void:
	play_sfx(STREAM_BUTTON_CLICK)
	_restart_level()
	hud.hide_popup()

func _on_hud_undo() -> void:
	_on_undo_requested()

func _on_hud_redo() -> void:
	_on_redo_requested()

func _on_hud_home() -> void:
	play_sfx(STREAM_BUTTON_CLICK)
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://title_menu.tscn")

func _on_hud_next_level() -> void:
	play_sfx(STREAM_BUTTON_CLICK)
	current_level_index += 1
	if current_level_index < LEVELS.size():
		# Load next level config and reset/re-initialize views
		current_level_data = load(LEVELS[current_level_index]) as LevelData
		_restart_level()
		hud.hide_popup()
		print("Loaded Level Index: ", current_level_index + 1)
	else:
		# Completed all levels! Reset index and return to main menu
		print("All levels completed! Returning to Main Menu.")
		current_level_index = 0
		get_tree().change_scene_to_file("res://title_menu.tscn")

func _restart_level() -> void:
	# Reset history and reload level model and view layouts
	history.clear()
	model.initialize(current_level_data)
	level_view.setup(model)
	_update_hud_states()

# Refreshes the persistent HUD buttons and step counters based on current model history values
func _update_hud_states() -> void:
	hud.update_history_buttons(history.can_undo(), history.can_redo())
	hud.update_cycles(model.remaining_cycles, model.max_cycles)

# Sets up background music with proper looping configuration in Godot 4
func _setup_background_music() -> void:
	bg_music_player = AudioStreamPlayer.new()
	bg_music_player.stream = STREAM_BG_MUSIC
	bg_music_player.volume_db = bgm_volume_db
	
	# Upcast to generic AudioStream to bypass static compile type checking
	var base_stream = STREAM_BG_MUSIC as AudioStream
	if base_stream is AudioStreamWAV:
		(base_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif base_stream is AudioStreamMP3:
		(base_stream as AudioStreamMP3).loop = true
		
	add_child(bg_music_player)
	bg_music_player.play()

# Plays overlapping one-shot SFX channels that free themselves from the tree on finish
func play_sfx(stream: AudioStream) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = sfx_volume_db
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
