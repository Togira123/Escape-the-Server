extends CharacterBody3D

@onready var armature = $Armature
@onready var animation_tree = $AnimationTree
@onready var animation_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var level = $"../Level"

const SPEED = 50
const JUMP_VELOCITY = 40
const LERP_VAL = 0.3
const FALL_ACCELERATION = 75

var has_spinned = false # makes sure players can only roll once after jumping
var is_jumping = false
var is_rolling = false

func _physics_process(delta):
	animation_tree.set("parameters/conditions/is_rolling", false)
	animation_tree.set("parameters/conditions/is_jumping", false)
	# Add the gravity
	if not is_on_floor():
		if not has_spinned and is_jumping and not is_rolling and Input.is_action_just_pressed("jump"):
			print("has_spinned ", has_spinned)
			print("is_jumping ", is_jumping)
			print("is_rolling ", is_rolling)
			print("stored_is_jumping ", animation_tree.get("parameters/conditions/is_jumping"))
			print("stored_is_rolling ", animation_tree.get("parameters/conditions/is_rolling"))
			animation_tree.set("parameters/conditions/is_spinning", true)
			#animation_state_machine.travel("jump_blend_tree")
			
			has_spinned = true
		
		if animation_tree.get("parameters/conditions/is_spinning"):
			velocity.y = 0.0
		else:
			velocity.y -= FALL_ACCELERATION * delta
	else:
		has_spinned = false
		is_jumping = false
	# 	Handle jump
		if Input.is_action_just_pressed("jump"):
			animation_tree.set("parameters/conditions/is_jumping", true)
			is_jumping = true
			velocity.y = JUMP_VELOCITY

	# Handle roll
	if Input.is_action_just_pressed("roll"):
		animation_tree.set("parameters/conditions/is_rolling", true)
		is_rolling = true

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
	
	#print(animation_tree.get("parameters/movements/blend_position"))
	#animation_tree.set("parameters/walk_to_run/blend_position", 1)
	
	# make sure to spawn in new ground
	if position.z > (level.module_count - level.LOADED_MODULES_SIZE + 2) * level.OFFSET:
		level.spawn_module(level.module_count * level.OFFSET)

	move_and_slide()


func _on_hitbox_area_entered(area):
	print("Hit letter!") # Replace with function body.


func _on_animation_tree_animation_started(anim_name):
	print("started", anim_name)

func _on_animation_tree_animation_finished(anim_name):
	print(anim_name)
	if anim_name == "spin":
		animation_tree.set("parameters/conditions/is_spinning", false)
	elif anim_name == "jump_blend_tree":
		is_jumping = false
	elif anim_name == "roll":
		is_rolling = false
