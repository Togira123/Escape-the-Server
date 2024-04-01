extends Camera3D

@onready var player = $"../Player"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.z = player.position.z - 2
	position.x = player.position.x
	position.y = player.position.y + 1
