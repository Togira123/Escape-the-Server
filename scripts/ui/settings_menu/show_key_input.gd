extends Button

@onready var press_key = $"../../../../PressKey"
@onready var bg = $"../../../../PressKey/Bg"

func _pressed():
	bg.call_deferred("grab_focus")
	press_key.map_name = name
	press_key.make_visible()
