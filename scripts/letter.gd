extends CharacterBody3D

@export var fall = false

@export var ACCELERATION = 9.81

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

var target_velocity = Vector3.ZERO

func _physics_process(delta):
	if not is_on_floor():
		target_velocity.y -= ACCELERATION * delta
		velocity = target_velocity
		move_and_slide()
