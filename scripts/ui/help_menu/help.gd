extends Panel

const DEFAULT = preload("res://assets/graphics/ui/main_menu/tab_default.png")
const SELECTED = preload("res://assets/graphics/ui/main_menu/tab_selected.png")

@onready var tab_bar = $TabBar
@onready var stats_overview = $"../StatsOverview"

func _gui_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close()
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

func _on_arrow_left_pressed():
	tab_bar.switch_to_left()

func _on_arrow_right_pressed():
	tab_bar.switch_to_right()
