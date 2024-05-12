extends Panel

const DEFAULT = preload("res://assets/graphics/ui/main_menu/tab_default.png")
const SELECTED = preload("res://assets/graphics/ui/main_menu/tab_selected.png")

@onready var tab_bar = $TabBar
@onready var settings_button_text = $"1/ButtonText"

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()

func _on_tab_bar_tab_changed(tab):
	var prev = tab_bar.get_previous_tab()
	tab_bar.set_tab_icon(prev, DEFAULT)
	tab_bar.set_tab_icon(tab, SELECTED)
	get_node(str(prev)).visible = false
	get_node(str(tab)).visible = true

func close():
	visible = false
	$"../TransparentBg".visible = false


func _on_check_button_toggled(toggled_on: bool):
	if toggled_on:
		InputMap.load_from_project_settings()
		settings_button_text.modulate = Color("ffffff")
	else:
		settings_button_text.modulate = Color("737373")
		# use non-default keybinds
		InputMap.action_erase_events("jump")
		InputMap.action_erase_events("roll")
		InputMap.action_erase_events("move_left")
		InputMap.action_erase_events("move_right")
		InputMap.action_erase_events("revive_up")
		InputMap.action_erase_events("revive_down")
		InputMap.action_erase_events("revive_left")
		InputMap.action_erase_events("revive_right")
		var jump = InputEventKey.new()
		jump.keycode = KEY_UP
		jump.pressed = true
		InputMap.action_add_event("jump", jump)
		var roll = InputEventKey.new()
		roll.keycode = KEY_DOWN
		roll.pressed = true
		InputMap.action_add_event("roll", roll)
		var move_left = InputEventKey.new()
		move_left.keycode = KEY_LEFT
		move_left.pressed = true
		InputMap.action_add_event("move_left", move_left)
		var move_right = InputEventKey.new()
		move_right.keycode = KEY_RIGHT
		move_right.pressed = true
		InputMap.action_add_event("move_right", move_right)
		var revive_up = InputEventKey.new()
		revive_up.keycode = KEY_W
		revive_up.pressed = true
		InputMap.action_add_event("revive_up", revive_up)
		var revive_down = InputEventKey.new()
		revive_down.keycode = KEY_S
		revive_down.pressed = true
		InputMap.action_add_event("revive_down", revive_down)
		var revive_left = InputEventKey.new()
		revive_left.keycode = KEY_A
		revive_left.pressed = true
		InputMap.action_add_event("revive_left", revive_left)
		var revive_right = InputEventKey.new()
		revive_right.keycode = KEY_D
		revive_right.pressed = true
		InputMap.action_add_event("revive_right", revive_right)
		
	Client.settings["default_keybinds"] = toggled_on
	Client.update_settings()
