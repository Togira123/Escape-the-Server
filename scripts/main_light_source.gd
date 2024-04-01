extends OmniLight3D

@onready var player = $"../Player"

func _ready():
	position.y = 10
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.z = player.position.z + 8
	position.x = player.position.x
