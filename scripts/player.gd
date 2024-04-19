extends CharacterBody3D

signal game_over

@onready var armature = $Armature
@onready var player_soul = $PlayerSoul
@onready var mesh = $Armature/Skeleton3D/Cube
@onready var animation_tree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var level = $"../Level"
@onready var hitbox_collision_shape := $"Hitbox/CollisionShape3D"
@onready var floor_collision = $FloorCollision
@onready var constants = $"../Constants"

const SPEED = 50
const WALK_SPEED = 1.5 * 60
const JUMP_VELOCITY = 40
const LERP_VAL = 0.3
const FALL_ACCELERATION = 75
const PLAYER_RUN_HEIGHT = 1.9
const PLAYER_RUN_OFFSET = -0.05
const PLAYER_JUMP_HEIGHT = 1.5
const PLAYER_JUMP_OFFSET = 0.1
const PLAYER_ROLL_HEIGHT = 1
const PLAYER_ROLL_OFFSET = -0.5

const DEATH_BREAK_SPEED = 10

const LASER_IMPULSE = 10
const LASER_IMPULSE_BREAK_SPEED = 0.5

const TUNNEL_JUMP_IMPULSE = 80
const TUNNEL_SPIN_HEIGHT = 43
const TUNNEL_SPEED: float = 250

var is_dead = false
var has_spinned = false # makes sure players can only roll once after jumping

var laser_impulse = 0.0 # holds current impulse when player touched laser

enum {RUN, ROLL, JUMP}

# used to change hitbox of the player
var just_changed = false
var cur_movement = RUN

# vars for tunnel
var started_spinning_in_tunnel = false
var jumped_in_tunnel = false
var changed_color_in_tunnel = false
var reached_height = false

# speed for start up
var startup_speed = 0.0

# used to make loop in death animation
var cur_speed = 0.0
var cur_angle = 0.0

func _ready():
	set_process(false)
	set_physics_process(false)

func _physics_process(delta):
	if is_dead:
		die_process(delta)
		return
	if position.y < 0:
		die()
		return
	if is_in_tunnel():
		if is_on_floor():
			jumped_in_tunnel = true
			velocity.y = TUNNEL_JUMP_IMPULSE
			state_machine.travel("jump_blend_tree")
			started_spinning_in_tunnel = false
			reached_height = false
		if jumped_in_tunnel:
			tunnel_process(delta)
			return
	jumped_in_tunnel = false
	changed_color_in_tunnel = false
	if just_changed:
		# change hitbox
		just_changed = false
		match cur_movement:
			RUN:
				hitbox_collision_shape.shape.height = PLAYER_RUN_HEIGHT
				hitbox_collision_shape.position.y = PLAYER_RUN_OFFSET
			JUMP:
				hitbox_collision_shape.shape.height = PLAYER_JUMP_HEIGHT
				hitbox_collision_shape.position.y = PLAYER_JUMP_OFFSET
			ROLL:
				hitbox_collision_shape.shape.height = PLAYER_ROLL_HEIGHT
				hitbox_collision_shape.position.y = PLAYER_ROLL_OFFSET

	if animation_tree.get("parameters/conditions/has_crashed"):
		return
	if not is_on_floor():
		if state_machine.get_current_node() != "run_blend_tree":
			animation_tree.set("parameters/conditions/is_jumping", false)
		if state_machine.get_current_node() == "roll":
			# Drop quickly if player is rolling
			velocity.y -= FALL_ACCELERATION * 3 * delta
		elif not has_spinned and state_machine.get_current_node() == "jump_blend_tree" and Input.is_action_just_pressed("jump"):
			state_machine.travel("spin_blend_tree")
			has_spinned = true
			just_changed = true
			cur_movement = RUN
		
		if state_machine.get_current_node() == "spin_blend_tree":
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
		if Input.is_action_just_pressed("jump") and state_machine.get_current_node() != "spin_blend_tree":
			state_machine.travel("jump_blend_tree")
			velocity.y = JUMP_VELOCITY
			just_changed = true
			cur_movement = JUMP
		elif cur_movement == JUMP:
			just_changed = true
			cur_movement = RUN


	# Handle roll
	if Input.is_action_just_pressed("roll") and state_machine.get_current_node() != "spin_blend_tree":
		state_machine.travel("roll")
		just_changed = true
		cur_movement = ROLL

	var direction = Vector3.ZERO
	direction.z = 1
	# Get inputs
	if Input.is_action_pressed("move_right"):
		direction.x = -0.9
	if Input.is_action_pressed("move_left"):
		direction.x += 0.9

	# Make sure vector has length 1
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		if laser_impulse > 0:
			direction.x += laser_impulse
			laser_impulse -= LASER_IMPULSE_BREAK_SPEED
		elif laser_impulse < 0:
			direction.x += laser_impulse
			laser_impulse += LASER_IMPULSE_BREAK_SPEED
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL)
	move_and_slide()

func _process(_delta):
	# make sure to spawn in new ground
	if position.z > (level.module_count - level.LOADED_MODULES_SIZE + 2) * level.OFFSET:
		level.spawn_module(level.module_count * level.OFFSET)
		for m in level.loaded_modules:
			if m:
				m.maybe_drop(position.z)

func is_in_tunnel():
	if level.next_tunnel > 0:
		var t = level.TUNNELS[level.next_tunnel - 1]
		if t < position.z and t + level.TUNNEL_LENGTH > position.z:
			return true
	return false

func tunnel_process(delta):
	velocity.z = lerp(velocity.z, TUNNEL_SPEED / 2.0, 0.4)
	velocity.x = lerp(velocity.x, -position.x, 0.5)
	get_tree().call_group("module", "change_color_of_pattern")
	if not changed_color_in_tunnel:
		constants.ground_pattern_color_change_progress = clamp(constants.ground_pattern_color_change_progress + delta * 2, 0.0, 1.0)
	if position.y > TUNNEL_SPIN_HEIGHT:
		reached_height = true
	if reached_height:
		# spin
		if state_machine.get_current_node() == "spin_blend_tree":
			velocity.y = 0.0
			rotation.x = lerp(rotation.x, PI / 2.0, LERP_VAL / 2.0)
			velocity.z = lerp(velocity.z, TUNNEL_SPEED, 0.8)
		else:
			if not started_spinning_in_tunnel:
				animation_tree.set("parameters/spin_blend_tree/TimeScale/scale", 0.5)
				state_machine.travel("spin_blend_tree")
				started_spinning_in_tunnel = true
			else:
				changed_color_in_tunnel = true
				if rotation.x != 0:
					rotation.x = lerp(rotation.x, 0.0, LERP_VAL / 2.0)
				# Gravity
				velocity.y -= FALL_ACCELERATION * delta
				animation_tree.set("parameters/spin_blend_tree/TimeScale/scale", 1.5)
				if level.TUNNELS[level.next_tunnel - 1] + level.TUNNEL_LENGTH - 10 > position.z:
					# only 10 meters left, make sure to set the progress back to 0
					constants.ground_pattern_color_change_progress = 0.0
				else:
					constants.ground_pattern_color_change_progress = clamp(constants.ground_pattern_color_change_progress - delta * 2, 0.0, 1.0)
	move_and_slide()

func start_running(delta):
	if state_machine.get_current_node() != "run_blend_tree":
		state_machine.travel("run_blend_tree")
	var direction = Vector3(-position.x, 0, 1)
	startup_speed += delta * 40
	if startup_speed > SPEED:
		animation_tree.set("parameters/run_blend_tree/TimeScale/scale", 1)
		set_process(true)
		set_physics_process(true)
		return false
	velocity.z = direction.z * startup_speed
	velocity.x = direction.x * startup_speed / 8
	armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL / 2)
	animation_tree.set("parameters/run_blend_tree/TimeScale/scale", 0.3 + startup_speed * 0.014)
	move_and_slide()
	return true

# initializes player death
func die():
	velocity.z = SPEED
	cur_speed = velocity.z
	is_dead = true
	player_soul.mesh.material.set_shader_parameter("turned_on", true)
	hitbox_collision_shape.set_deferred("disabled", true)
	floor_collision.set_deferred("disabled", true)
	animation_tree.set("parameters/conditions/has_crashed", true)

# function to process the player death animation
func die_process(delta):
	var old_val = mesh.material_override.get_shader_parameter("dissolve_amount")
	if old_val < 1:
		mesh.material_override.set_shader_parameter("dissolve_amount", old_val + 0.05)
	else:
		armature.visible = false	
	
	if velocity.z < SPEED * 0.9:
		# do loop
		if cur_speed < 0:
			set_physics_process(false)
			game_over.emit()
			return
		var vel_z = cos(cur_angle)
		var vel_y = sin(cur_angle)
		velocity.z = vel_z * cur_speed
		velocity.y = vel_y * cur_speed
		cur_speed -= delta * DEATH_BREAK_SPEED
		# 2.2 * PI causes the sphere to move up a bit at the end
		if cur_angle < 2.2 * PI:
			cur_angle = (SPEED * 0.9 - cur_speed) * (2 * PI / (SPEED * 0.9)) * 4
	else:
		velocity.z -= delta * DEATH_BREAK_SPEED
		cur_speed = velocity.z
		velocity.x = lerp(velocity.x, 0.0, 0.8)
		if position.y < 0:
			velocity.y = lerp(velocity.y, JUMP_VELOCITY * 2.0, 0.9)
		else:
			velocity.y = lerp(velocity.y, JUMP_VELOCITY / 4.0, 0.8)
		if velocity.z < 0:
			velocity.z = 0
	
	move_and_slide()
	

func _on_hitbox_area_entered(area: Area3D):
	player_was_hit(area)

func _on_hitbox_area_exited(area: Area3D):
	player_was_hit(area)
	
func player_was_hit(area: Area3D):
	if area.name == "LetterHitbox":
		# player hit laser
		die()
	else:
		velocity.y = LASER_IMPULSE * 4
		if position.x > 0:
			laser_impulse = -LASER_IMPULSE
		else:
			laser_impulse = LASER_IMPULSE

func move_to_random_point(x, z, delta):
	if abs(position.x - x) < 0.2 or abs(position.z - z) < 0.2:
		state_machine.travel("idle")
		return true
	if state_machine.get_current_node() != "walk":
		state_machine.travel("walk")
	var target = Vector3(x, position.y, z)
	var direction = target - position
	direction = direction.normalized()
	velocity.x = direction.x * WALK_SPEED * delta
	velocity.z = direction.z * WALK_SPEED * delta
	armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL / 2)
	move_and_slide()
	return false

func _on_animation_tree_animation_finished(anim_name):
	if anim_name == "roll":
		just_changed = true
		cur_movement = RUN
