extends Control

@onready var countdown = $Countdown
@onready var arrow = $"../../Arrow"
@onready var teleport = $"../../Teleport"
@onready var teleport_count = $"../../Teleport/Count"
@onready var teleport_sprite = $"../../Teleport/Teleport"

var timer: SceneTreeTimer = null
var time_passed = 0.0

func _ready():
	arrow.visible = true
	if teleport_count.text == "0":
		teleport_sprite.modulate.a = 0.0
		teleport_count.visible = false
		teleport.visible = true

func _process(delta):
	if not timer:
		arrow.visible = false
		if teleport_count.text == "0":
			teleport.visible = false
		queue_free()
		return
	var time_left = timer.get_time_left()
	if time_left <= 0.0:
		arrow.visible = false
		if teleport_count.text == "0":
			teleport.visible = false
		queue_free()
		return
	countdown.text = str(ceil(time_left))
	# flash arrow
	time_passed += delta * 4
	arrow.material.set_shader_parameter("inside_color", Color(1.0, 1.0, 1.0, (sin(time_passed) + 1) / 2))
	# if there's no teleports available also flash teleports
	if teleport_count.text == "0":
		teleport_sprite.modulate.a = (sin(time_passed) + 1) / 2
