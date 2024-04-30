extends Control

@onready var countdown = $Countdown

var timer: SceneTreeTimer = null

func _process(_delta):
	if not timer:
		queue_free()
		return
	var time_left = timer.get_time_left()
	if time_left <= 0.0:
		queue_free()
		return
	countdown.text = str(ceil(time_left))
