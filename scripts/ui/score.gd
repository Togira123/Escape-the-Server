extends Label

@onready var player = $"../../../Player"
@onready var level = $"../../../Level"

var finish

# Called when the node enters the scene tree for the first time.
func _ready():
	finish = level.TUNNELS[level.TUNNELS.size() - 1]
	text = str(finish) +  " Micrometers left"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Client.gamemode == "casual":
		text = str(clamp(finish - int(player.position.z), 0, finish)) + " Micrometers left"
	else:
		text = "Micrometers run: " + str(int(max(0, player.position.z)))
