extends CharacterBody3D

@export var speed = 14

@export var fall_acceleration = 75

@export var jump_impulse = 20

var target_velocity = Vector3.ZERO

func _physics_process(delta):
	var direction = Vector3.ZERO
	direction.z -= 1
	# Get inputs
	if Input.is_action_pressed("move_right"):
		direction.x += 0.5
	if Input.is_action_pressed("move_left"):
		direction.x -= 0.5

	# Make sure vector has length 1
	if direction != Vector3.ZERO:
		direction = direction.normalized()

		$Pivot.basis = Basis.looking_at(direction)

	# Ground velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical velocity
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta

	# Move character
	velocity = target_velocity

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	move_and_slide()
