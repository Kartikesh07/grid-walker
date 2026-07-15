extends CanvasLayer

signal restart_requested()
signal undo_requested()

@onready var popup: Panel = $GameEndPopup
@onready var title_label: Label = $GameEndPopup/TitleLabel
@onready var restart_button: Button = $GameEndPopup/RestartButton
@onready var undo_button: Button = $GameEndPopup/UndoButton

# Color presets for popup borders
const COLOR_VICTORY_BORDER = Color("39ff14") # Neon green
const COLOR_BREACH_BORDER = Color("ff3131")  # Neon red

func _ready() -> void:
	# Hide the popup by default on start
	popup.hide()
	
	# Connect buttons to emit custom HUD signals
	restart_button.pressed.connect(func(): restart_requested.emit())
	undo_button.pressed.connect(func(): undo_requested.emit())

func show_victory() -> void:
	title_label.text = "SYSTEM CLEANSED"
	set_popup_border_color(COLOR_VICTORY_BORDER)
	popup.show()

func show_breach() -> void:
	title_label.text = "SECURITY COMPROMISED"
	set_popup_border_color(COLOR_BREACH_BORDER)
	popup.show()

func hide_popup() -> void:
	popup.hide()

# Helper to dynamically update the border color of the panel's flat StyleBox
func set_popup_border_color(color: Color) -> void:
	var stylebox = popup.get_theme_stylebox("panel") as StyleBoxFlat
	if stylebox:
		# We duplicate the stylebox to prevent changing the resource globally
		var dup_stylebox = stylebox.duplicate() as StyleBoxFlat
		dup_stylebox.border_color = color
		popup.add_theme_stylebox_override("panel", dup_stylebox)
