extends Control

@onready var label = $Label
@onready var label2 = $Label2

var map_name: String

static var _m = {
	"key_move_left": 0,
	"key_move_right": 0,
	"key_jump": 0,
	"key_roll": 0,
	"key_use_item": 0,
	"key_revive_down": 1,
	"key_revive_up": 1,
	"key_revive_right": 1,
	"key_revive_left": 1,
	"key_build_ramp": 2,
	"key_build_ceiling": 2,
	"key_toggle_build_indicator": 2
}

var timer: SceneTreeTimer
var cancelled = false

func make_visible():
	label.text = "Press any key or mouse button"
	label2.visible = true
	visible = true
	cancelled = false
	timer = get_tree().create_timer(5, true, false, true)
	await timer.timeout
	if not cancelled:
		visible = false
	

func _on_bg_gui_input(event: InputEvent):
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		cancelled = true
		accept_event()
		if map_name.length() > 0:
			InputMap.action_erase_events(map_name)
			InputMap.action_add_event(map_name, event)
			if event is InputEventMouseButton:
				event.double_click = false
			var num = 0
			if event is InputEventKey:
				num = event.keycode
			else:
				num = event.button_index
			# check for duplicates
			for k in Client.settings:
				if k.begins_with("key_") and k != "key_" + map_name:
					if Client.settings[k] == num:
						if _m["key_" + map_name] == 0 or _m[k] == 0 or _m[k] == _m["key_" + map_name]:
							label.text = "Keybinds can only overlap between the \"Ranked\" and \"Casual\" categories"
							label2.visible = false
							return
			var txt = event.as_text()
			if event is InputEventKey and (event.keycode == KEY_UP or event.keycode == KEY_DOWN or event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT):
				txt = "Arrow " + txt
			get_node("../1/ScrollContainer/GridContainer/" + map_name).text = txt
			Client.settings["key_" + map_name] = num
			Client.update_settings()
			visible = false
			timer.time_left = 0.0
