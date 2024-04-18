extends Label

@onready var player = $"../../Player"

# Called when the node enters the scene tree for the first time.
func _ready():
	text = "0 Meters"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = str(int(player.position.z if player.position.z > 0 else 0)) + " Meters"
