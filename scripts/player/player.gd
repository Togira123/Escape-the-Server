extends CharacterBody3D

signal game_over

@onready var armature = $Armature
@onready var player_soul = $PlayerSoul
@onready var mesh = $Armature/Skeleton3D/Skin
@onready var animation_tree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

@onready var level = $"../Level"
@onready var heat_control: Control = $"../Level/UI/Heat"
@onready var heat_effect: TextureRect = $"../Level/UI/HeatEffect"
@onready var heat_status: Control = $"../Level/UI/Heat/HeatStatus"
@onready var heat_bar: ColorRect = $"../Level/UI/Heat/HeatBar"
@onready var player_shield = $"PlayerShield"
@onready var hitbox_collision_shape := $"Hitbox/CollisionShape3D"
@onready var floor_collision = $FloorCollision
@onready var constants = $"../Constants"
@onready var camera = $"../PlayerCamera"

var speed = 50
const RUN_SPEEDS = [50, 65, 80]
const WALK_SPEED = 1.5 * 60
const JUMP_VELOCITY = 40
const LERP_VAL = 0.3
const FALL_ACCELERATION = 75
const PLAYER_RUN_HEIGHT = 1.9
const PLAYER_RUN_OFFSET = -0.05
const PLAYER_JUMP_HEIGHT = 1.5
const PLAYER_JUMP_OFFSET = 0.1
const PLAYER_ROLL_HEIGHT = 1.0
const PLAYER_ROLL_OFFSET = -0.5

const DEATH_BREAK_SPEED = 10

var laser_impulse = 8
const LASER_IMPULSES = [8, 11]
const LASER_IMPULSE_BREAK_SPEED = 0.5

const TUNNEL_JUMP_IMPULSE = 80
const TUNNEL_SPIN_HEIGHT = 43
const TUNNEL_SPEED: float = 250

const SHIELD_DURATION = 5.0
const TELEPORT_DISTANCE = 40

const PLATFORM_LENGTH = [1500, 2000]

var is_dead = false
var is_finished = false
var has_spinned = false # makes sure players can only roll once after jumping

var has_shield_active = false
var shield_timer: SceneTreeTimer = null

var teleport_count = 0
var letters_passed = 0

var heat = 0.0 # stores how heated the player is – dies at 40
const HEAT_DEATH = 40.0

var player_laser_impulse = 0.0 # holds current impulse when player touched laser

enum {RUN, ROLL, JUMP}

# used to change hitbox of the player
var cur_movement = RUN
const LERP_VAL_MOV_CHANGE = 0.3

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

var spawn_platforms = false

func _ready():
	set_process(false)
	set_physics_process(false)

func _physics_process(delta):
	if is_finished and camera.position.z + camera.far * 2 < position.z:
		set_physics_process(false)
	if is_dead:
		die_process(delta)
		return
	if position.y < -1 or heat > HEAT_DEATH:
		die()
		return
	var cur_tunnel = is_in_tunnel();
	if cur_tunnel != -1 or is_finished:
		var last = cur_tunnel == level.TUNNELS.size()
		if is_on_floor():
			level.stage = cur_tunnel
			jumped_in_tunnel = true
			velocity.y = TUNNEL_JUMP_IMPULSE
			state_machine.travel("jump_blend_tree")
			started_spinning_in_tunnel = false
			reached_height = false
			if not last:
				var lasers = level.get_child(0)
				lasers.remove_children()
				lasers.spawn_lasers(level.stage)
				speed = RUN_SPEEDS[cur_tunnel]
				var old_anim_speed = animation_tree.get("parameters/run_blend_tree/TimeScale/scale")
				animation_tree.set("parameters/run_blend_tree/TimeScale/scale", old_anim_speed + 0.3)
				laser_impulse = LASER_IMPULSES[clamp(cur_tunnel, 0, 1)]
		if jumped_in_tunnel:
			tunnel_process(delta, last)
			return
	jumped_in_tunnel = false
	changed_color_in_tunnel = false
	# change hitbox
	match cur_movement:
		RUN:
			hitbox_collision_shape.shape.height = lerp(hitbox_collision_shape.shape.height, PLAYER_RUN_HEIGHT, LERP_VAL_MOV_CHANGE)
			hitbox_collision_shape.position.y = lerp(hitbox_collision_shape.position.y, PLAYER_RUN_OFFSET, LERP_VAL_MOV_CHANGE)
			player_shield.mesh.height = lerp(player_shield.mesh.height, PLAYER_RUN_HEIGHT, LERP_VAL_MOV_CHANGE)
			player_shield.position.y = lerp(player_shield.position.y, PLAYER_RUN_OFFSET, LERP_VAL_MOV_CHANGE)
		JUMP:
			hitbox_collision_shape.shape.height = lerp(hitbox_collision_shape.shape.height, PLAYER_JUMP_HEIGHT, LERP_VAL_MOV_CHANGE)
			hitbox_collision_shape.position.y = lerp(hitbox_collision_shape.position.y, PLAYER_JUMP_OFFSET, LERP_VAL_MOV_CHANGE)
			player_shield.mesh.height = lerp(player_shield.mesh.height, PLAYER_JUMP_HEIGHT, LERP_VAL_MOV_CHANGE)
			player_shield.position.y = lerp(player_shield.position.y, PLAYER_JUMP_OFFSET, LERP_VAL_MOV_CHANGE)
		ROLL:
			hitbox_collision_shape.shape.height = lerp(hitbox_collision_shape.shape.height, PLAYER_ROLL_HEIGHT, LERP_VAL_MOV_CHANGE / 2.0)
			hitbox_collision_shape.position.y = lerp(hitbox_collision_shape.position.y, PLAYER_ROLL_OFFSET, LERP_VAL_MOV_CHANGE / 2.0)
			player_shield.mesh.height = lerp(player_shield.mesh.height, PLAYER_ROLL_HEIGHT, LERP_VAL_MOV_CHANGE / 2.0)
			player_shield.position.y = lerp(player_shield.position.y, PLAYER_ROLL_OFFSET, LERP_VAL_MOV_CHANGE / 2.0)

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
			cur_movement = JUMP
		elif cur_movement == JUMP:
			cur_movement = RUN


	# Handle roll
	if Input.is_action_just_pressed("roll") and state_machine.get_current_node() != "spin_blend_tree":
		state_machine.travel("roll")
		cur_movement = ROLL

	var direction = Vector3.ZERO
	direction.z = 1
	# Get inputs
	if Input.is_action_pressed("move_right"):
		direction.x = -0.9
	if Input.is_action_pressed("move_left"):
		direction.x += 0.9

	if Input.is_action_just_pressed("use_item") and teleport_count > 0:
		teleport_count -= 1
		level.change_ability_count(level.ABILITIES.TELEPORT, teleport_count)
		position.z += TELEPORT_DISTANCE
		camera.distance_to_player = TELEPORT_DISTANCE
	
	# apply heat if player is too close to lasers
	var abs_pos_x = abs(position.x)
	if abs_pos_x >= 70:
		heat += (abs_pos_x - 70) * delta
		heat_effect.material.set_shader_parameter("alpha", heat / HEAT_DEATH * 0.7)
		heat_status.position.y = (1 - heat / HEAT_DEATH) * 303
		if heat_control.modulate.a < 1:
			heat_control.set_modulate(Color(1.0, 1.0, 1.0, min(1.0, heat_control.modulate.a + delta * 2)))
			heat_bar.material.set_shader_parameter("alpha", heat_control.modulate.a)
	elif heat > 0:
		heat = max(0, heat - 4 * delta)
		heat_effect.material.set_shader_parameter("alpha", heat / HEAT_DEATH * 0.7)
		heat_status.position.y = (1 - heat / HEAT_DEATH) * 303
	elif heat_control.modulate.a > 0:
		heat_control.set_modulate(Color(1.0, 1.0, 1.0, max(0.0, heat_control.modulate.a - delta * 2)))
		heat_bar.material.set_shader_parameter("alpha", heat_control.modulate.a)
	# Make sure vector has length 1
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		if player_laser_impulse > 0:
			direction.x += player_laser_impulse
			player_laser_impulse -= LASER_IMPULSE_BREAK_SPEED
		elif player_laser_impulse < 0:
			direction.x += player_laser_impulse
			player_laser_impulse += LASER_IMPULSE_BREAK_SPEED
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL)
	move_and_slide()

func _process(_delta):
	spawn_platforms = level.next_tunnel < level.TUNNELS.size() and position.z + PLATFORM_LENGTH[level.next_tunnel - 1] > level.TUNNELS[level.next_tunnel]
	var pos = position.z if not is_finished else camera.position.z
	# make sure to spawn in new ground
	if pos > (level.module_count - level.LOADED_MODULES_SIZE + 2) * level.OFFSET:
		level.spawn_module(level.module_count * level.OFFSET, spawn_platforms)
		for m in level.loaded_modules:
			if m:
				m.maybe_drop(pos)

func is_in_tunnel():
	if level.next_tunnel > 0:
		var t = level.TUNNELS[level.next_tunnel - 1]
		if t < position.z and t + level.TUNNEL_LENGTH > position.z:
			return level.next_tunnel
	return -1

func tunnel_process(delta, is_last: bool):
	velocity.z = lerp(velocity.z, TUNNEL_SPEED / 2.0, 0.4)
	velocity.x = lerp(velocity.x, -position.x, 0.5)
	armature.rotation.y = lerp_angle(armature.rotation.y, atan2(velocity.x, velocity.z), LERP_VAL)
	get_tree().call_group("module", "change_color_of_pattern")
	if not changed_color_in_tunnel:
		constants.ground_pattern_color_change_progress = clamp(constants.ground_pattern_color_change_progress + delta * 2, 0.0, 1.0)
	if position.y > TUNNEL_SPIN_HEIGHT:
		reached_height = true
	if is_last and position.y > TUNNEL_SPIN_HEIGHT / 2:
		is_finished = true
		set_process(false)
	if reached_height:
		# spin
		if state_machine.get_current_node() == "spin_blend_tree" or is_finished:
			velocity.y = 0.0
			rotation.x = lerp(rotation.x, PI / 2.0, LERP_VAL / 2.0)
			velocity.z = lerp(velocity.z, TUNNEL_SPEED * (3 if is_last else 1), 0.8)
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
	if startup_speed > speed:
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
	if shield_timer:
		shield_timer.set_time_left(0.0)
	velocity.z = speed
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
	
	if velocity.z < speed * 0.9:
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
			cur_angle = (speed * 0.9 - cur_speed) * (2 * PI / (speed * 0.9)) * 4
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
	
func _on_hitbox_area_exited(area):
	if not is_dead and area.name == "ShieldHitbox":
		# apply shield
		if shield_timer:
			# there's already an active timer, reset its time
			shield_timer.set_time_left(SHIELD_DURATION)
			# since there is already a shield, add one more teleport
			letters_passed += 1
			if letters_passed % 2 == 0:
				teleport_count = clamp(teleport_count + 1, 0, level.MAX_TELEPORT_ABILITIES)
			level.change_ability_count(level.ABILITIES.TELEPORT, teleport_count)
		else:
			# create a new timer and reset shield when it ends
			letters_passed = 1
			shield_timer = get_tree().create_timer(SHIELD_DURATION, true, true)
			has_shield_active = true
			player_shield.mesh.material.set_shader_parameter("alpha", 0.5)
			level.add_status_effect(level.STATUS_EFFECTS.SHIELD, shield_timer)
			await shield_timer.timeout
			has_shield_active = false
			player_shield.mesh.material.set_shader_parameter("alpha", 0.0)
			shield_timer = null
		
	
func player_was_hit(area: Area3D):
	if area.name == "LetterHitbox":
		# player hit laser
		if has_shield_active:
			shield_timer.set_time_left(0.0)
			Engine.set_time_scale(0.01)
			area.get_parent().dissolve()
			await get_tree().create_timer(0.5, true, true, true).timeout
			Engine.set_time_scale(1.0)
		else:
			die()
	elif area.name == "ShieldHitbox":
		# hit shield, apply it when exiting the area
		return
	else:
		if level.stage == 2:
			die()
			return
		velocity.y = laser_impulse * 4
		if position.x > 0:
			player_laser_impulse = -laser_impulse
		else:
			player_laser_impulse = laser_impulse

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

func _on_animation_tree_animation_started(anim_name):
	if anim_name == "roll":
		await get_tree().create_timer(0.4, true, true).timeout
		if cur_movement == ROLL:
			cur_movement = RUN

func set_color(col: Color):
	mesh.material_override.set_shader_parameter("albedo", col)
