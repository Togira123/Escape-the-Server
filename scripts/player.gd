extends CharacterBody3D

@onready var armature = $Armature
@onready var animation_tree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var level = $"../Level"

const SPEED = 50
const JUMP_VELOCITY = 40
const LERP_VAL = 0.3
const FALL_ACCELERATION = 75

var has_spinned = false # makes sure players can only roll once after jumping

func _physics_process(delta):
	if animation_tree.get("parameters/conditions/has_crashed"):
		return
	animation_tree.set("parameters/conditions/is_rolling", false)
	if not is_on_floor():
		if state_machine.get_current_node() != "run":
			animation_tree.set("parameters/conditions/is_jumping", false)
		if state_machine.get_current_node() == "roll":
			# Drop quickly if player is rolling
			velocity.y -= FALL_ACCELERATION * 3 * delta
		elif not has_spinned and state_machine.get_current_node() == "jump_blend_tree" and Input.is_action_just_pressed("jump"):
			animation_tree.set("parameters/conditions/is_spinning", true)
			has_spinned = true
		
		if animation_tree.get("parameters/conditions/is_spinning"):
			rotation.x = lerp(rotation.x, PI / 2.0, LERP_VAL / 2.0)
			velocity.y = 0.0
		else:
			if rotation.x != 0:
				rotation.x = lerp(rotation.x, 0.0, LERP_VAL / 2.0)
			# Gravity
			velocity.y -= FALL_ACCELERATION * delta
	else:
		has_spinned = false
		# make sure that character is standing normal after spinning
		rotation.x = 0
	# 	Handle jump
		if Input.is_action_just_pressed("jump"):
			animation_tree.set("parameters/conditions/is_jumping", true)
			velocity.y = JUMP_VELOCITY

	# Handle roll
	if Input.is_action_just_pressed("roll"):
		animation_tree.set("parameters/conditions/is_rolling", true)

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
	
	# make sure to spawn in new ground
	if position.z > (level.module_count - level.LOADED_MODULES_SIZE + 2) * level.OFFSET:
		level.spawn_module(level.module_count * level.OFFSET)

	move_and_slide()

func _on_hitbox_area_entered(area):
	print("Hit letter!") # Replace with function body.
	#animation_tree.set("parameters/conditions/has_crashed", true)
	#velocity.z = 0



func _on_animation_tree_animation_started(anim_name):
	print("started", anim_name)

func _on_animation_tree_animation_finished(anim_name):
	print(anim_name)
	if anim_name == "spin":
		animation_tree.set("parameters/conditions/is_spinning", false)
