extends Panel

const DEFAULT = preload("res://assets/graphics/ui/main_menu/tab_default.png")
const SELECTED = preload("res://assets/graphics/ui/main_menu/tab_selected.png")

@onready var tab_bar = $TabBar
@onready var stats_overview = $"../StatsOverview"
@onready var leaderboard = $"../Leaderboard"

const ACTIONS = [
	"move_left",
	"move_right",
	"jump",
	"roll",
	"use_item",
	"revive_down",
	"revive_up",
	"revive_right",
	"revive_left",
	"build_ramp",
	"build_ceiling",
	"toggle_build_indicator"
]

func _gui_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close()
		if Client.lobby.members[Client.user_id].gamemode == "ranked":
			leaderboard.visible = true
		else:
			stats_overview.visible = true
	elif event.is_action_pressed("ui_left", true):
		accept_event()
		tab_bar.switch_to_left()
	elif event.is_action_pressed("ui_right", true):
		accept_event()
		tab_bar.switch_to_right()

func _on_tab_bar_tab_changed(tab):
	var prev = tab_bar.get_previous_tab()
	tab_bar.set_tab_icon(prev, DEFAULT)
	tab_bar.set_tab_icon(tab, SELECTED)
	get_node(str(prev)).visible = false
	get_node(str(tab)).visible = true

func close():
	visible = false
	$"../TransparentBg".visible = false

func load_keybinds_from_settings():
	for k in Client.settings:
		if k.begins_with("key_"):
			var action_name = k.substr(4)
			InputMap.action_erase_events(action_name)
			var txt = ""
			if Client.settings[k] < 20:
				# mouse button
				var input = InputEventMouseButton.new()
				input.pressed = true
				input.button_index = Client.settings[k]
				InputMap.action_add_event(action_name, input)
				txt = input.as_text()
			else:
				var input = InputEventKey.new()
				input.pressed = true
				input.keycode = Client.settings[k]
				InputMap.action_add_event(action_name, input)
				txt = input.as_text()
				if input.keycode == KEY_UP or input.keycode == KEY_DOWN or input.keycode == KEY_LEFT or input.keycode == KEY_RIGHT:
					txt = "Arrow " + txt
			get_node("1/ScrollContainer/GridContainer/" + action_name).text = txt

func _on_arrow_left_pressed():
	tab_bar.switch_to_left()


func _on_arrow_right_pressed():
	tab_bar.switch_to_right()


func _on_hex_text_submitted(_new_text: String) -> void:
	call_deferred("grab_focus")


func _on_reset_keybinds_pressed():
	InputMap.load_from_project_settings()
	for action in ACTIONS:
		var input = InputMap.action_get_events(action)[0]
		var txt = input.as_text()
		if input.keycode == KEY_UP or input.keycode == KEY_DOWN or input.keycode == KEY_LEFT or input.keycode == KEY_RIGHT:
			txt = "Arrow " + txt
		get_node("1/ScrollContainer/GridContainer/" + action).text = txt
		Client.settings["key_" + action] = input.keycode
	Client.update_settings()
