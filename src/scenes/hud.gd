extends CanvasLayer

signal restart_requested()
signal undo_requested()
signal redo_requested()

# Popup nodes
@onready var popup: Panel = $GameEndPopup
@onready var title_label: Label = $GameEndPopup/TitleLabel
@onready var restart_button: Button = $GameEndPopup/RestartButton
@onready var undo_button: Button = $GameEndPopup/UndoButton

# Persistent HUD nodes
@onready var undo_hud_button: Button = $ControlButtons/UndoHUDButton
@onready var redo_hud_button: Button = $ControlButtons/RedoHUDButton
@onready var cycles_label: Label = $CyclesLabel

# Color presets for popup borders
const COLOR_VICTORY_BORDER = Color("39ff14") # Neon green
const COLOR_BREACH_BORDER = Color("ff3131")  # Neon red

func _ready() -> void:
	# Hide the popup by default on start
	popup.hide()
	
	# Connect popup buttons
	restart_button.pressed.connect(func(): restart_requested.emit())
	undo_button.pressed.connect(func(): undo_requested.emit())
	
	# Connect persistent bottom HUD buttons
	undo_hud_button.pressed.connect(func(): undo_requested.emit())
	redo_hud_button.pressed.connect(func(): redo_requested.emit())

func show_victory() -> void:
	title_label.text = "SYSTEM CLEANSED"
	set_popup_border_color(COLOR_VICTORY_BORDER)
	popup.show()
	update_history_buttons(false, false)

func show_breach() -> void:
	title_label.text = "SECURITY COMPROMISED"
	set_popup_border_color(COLOR_BREACH_BORDER)
	popup.show()
	update_history_buttons(false, false)

func hide_popup() -> void:
	popup.hide()

# Updates the cycles count label text
func update_cycles(remaining: int, max_val: int) -> void:
	if cycles_label:
		cycles_label.text = "CYCLES: " + str(remaining) + " / " + str(max_val)

# Updates the button enabled/disabled states based on historical stack sizes
func update_history_buttons(can_undo: bool, can_redo: bool) -> void:
	if popup.visible:
		# Lock background buttons if victory/loss overlay is shown
		undo_hud_button.disabled = true
		redo_hud_button.disabled = true
	else:
		undo_hud_button.disabled = not can_undo
		redo_hud_button.disabled = not can_redo

# Helper to dynamically update the border color of the panel's flat StyleBox
func set_popup_border_color(color: Color) -> void:
	var stylebox = popup.get_theme_stylebox("panel") as StyleBoxFlat
	if stylebox:
		var dup_stylebox = stylebox.duplicate() as StyleBoxFlat
		dup_stylebox.border_color = color
		popup.add_theme_stylebox_override("panel", dup_stylebox)
