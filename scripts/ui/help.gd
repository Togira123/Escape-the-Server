extends Panel

const DEFAULT = preload("res://assets/graphics/ui/main_menu/tab_default.png")
const SELECTED = preload("res://assets/graphics/ui/main_menu/tab_selected.png")

@onready var tab_bar = $TabBar

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

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
