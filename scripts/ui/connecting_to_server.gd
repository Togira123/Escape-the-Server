extends Control

@onready var loading_inside = $LoadingInside

func _ready():
	await Client.on_authorize
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	loading_inside.size.x = lerp(loading_inside.size.x, 644.0 * Client.connecting_to_server_percentage, 4 * delta)
