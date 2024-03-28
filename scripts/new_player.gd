extends CharacterBody3D

@onready var armature = $Armature
@onready var animation_tree = $AnimationTree

@onready var level = $"../Level"

const SPEED = 50
const JUMP_VELOCITY = 40
const LERP_VAL = 0.15
const FALL_ACCELERATION = 75


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= FALL_ACCELERATION * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Vector3.ZERO
	direction.z += 1
	# Get inputs
	if Input.is_action_pressed("move_right"):
		direction.x -= 0.9
	if Input.is_action_pressed("move_left"):
		direction.x += 0.9

	# Make sure vector has length 1
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	animation_tree.set("parameters/BlendSpace1D/blend_position", 1)
	
	# make sure to spawn in new ground
	if position.z > (level.module_count - level.LOADED_MODULES_SIZE + 2) * level.OFFSET:
		level.spawn_module(level.module_count * level.OFFSET)

	move_and_slide()
