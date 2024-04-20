extends Label

@onready var player = $"../../../Player"
@onready var level = $"../../../Level"

# Called when the node enters the scene tree for the first time.
func _ready():
	text = str(level.TUNNELS[level.TUNNELS.size() - 1]) +  " Micrometers left"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	text = str(clamp(level.TUNNELS[level.TUNNELS.size() - 1] - int(player.position.z), 0, level.TUNNELS[level.TUNNELS.size() - 1])) + " Micrometers left"
