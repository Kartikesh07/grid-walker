extends Control

# Preload sound effect directly for UI clicks
const STREAM_BUTTON_CLICK = preload("res://Music/ButtonClick.wav")

# Use Scene Unique Nodes (%) to find buttons anywhere in the hierarchy
@onready var start_button: Button = %StartButton
@onready var exit_button: Button = %ExitButton

func _ready() -> void:
	# Connect buttons to their press events
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	play_sfx(STREAM_BUTTON_CLICK)
	# Wait brief moment for the click sound to finish playing, then switch scenes
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://main.tscn")

func _on_exit_pressed() -> void:
	play_sfx(STREAM_BUTTON_CLICK)
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

# Simple one-shot sound player
func play_sfx(stream: AudioStream) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -6.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
