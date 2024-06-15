extends Node3D

@onready var level = $"../../Level"
@onready var player = $"../../Player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	set_process(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x = ceil(player.position.x * 5 / 100) * 20 - 10
	position.z = ceil(player.position.z / 40) * 40 + 20
	print(position.z)
