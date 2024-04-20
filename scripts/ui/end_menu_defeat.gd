extends Control

@onready var player_soul = $PlayerSoul

var moved_up = false

var wobble_time = 0.0

# Called when the n	ode enters the scene tree for the first time.
func _ready():
	# make sure player soul is visible
	player_soul.mesh.material.set_shader_parameter("turned_on", true)
	$EndMenuCamera.make_current()

func _physics_process(delta):
	if not moved_up:
		moved_up = move_up()
	else:
		wobble(delta)

func _on_main_menu_button_pressed():
	$"../../Main".restart_game()

func wobble(delta):
	player_soul.position.y = sin(wobble_time) / 16.0
	wobble_time += delta

func move_up():
	if player_soul.position.y < 0:
		player_soul.position.y = lerp(player_soul.position.y, 0.05, 0.01)
		return false
	return true
