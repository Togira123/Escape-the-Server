extends AudioStreamPlayer

func _ready():
	set_process(false)
var _multiplier = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	volume_db -= delta * _multiplier
	_multiplier += delta * 60
	if volume_db <= -80:
		stop()
		volume_db = 0
		_multiplier = 0
		set_process(false)

func fade_out():
	set_process(true)
