extends AnimatableBody3D

@export var fall = false

@export var GRAVITY = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

var prev_velocity = Vector3.ZERO

func _physics_process(delta):
	if not fall:
		return
	prev_velocity.y -= GRAVITY * delta
	move_and_collide(prev_velocity)
