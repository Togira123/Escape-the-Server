extends Control

@onready var chosen_color = $ChosenColor
@onready var color_wheel = $ColorWheel
@onready var color_wheel_dot = $ColorWheelDot
@onready var hex = $Hex
@onready var slider_r = $SliderR
@onready var slider_g = $SliderG
@onready var slider_b = $SliderB
@onready var slider_v = $SliderV

@onready var player = $"../../../Player"

var mouse_pressed_for_color_picker = false
var wheel_radius: float
var wheel_center: Vector2
var wheel_dot_radius: float

func _ready():
	wheel_radius = color_wheel.texture.get_height() * color_wheel.scale.x / 2
	wheel_center = Vector2(color_wheel.position.x + wheel_radius, color_wheel.position.y + wheel_radius)
	wheel_dot_radius = color_wheel_dot.texture.get_height() * color_wheel_dot.scale.x / 2

func rgb_to_hsv(color: Color):
	var K = Vector4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0)
	var p = Vector4(color.b, color.g, K.w, K.z).lerp(Vector4(color.g, color.b, K.x, K.y), int(color.b > color.g))
	p = Vector4(p.x, p.y, p.w, color.r).lerp(Vector4(color.r, p.y, p.x, p.z), int(p.x > color.r))
	
	var d = p.x - min(p.w, p.y)
	var e = 1.0e-10
	return Vector3(abs(p.z + (p.w - p.y) / (6.0 * d + e)), d / (p.x + e), p.x)

func fract(x):
	return x - floor(x)

func hsv_to_rgb(c: Vector3):
	var K = Vector4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0)
	var p = abs(fract(Vector3(c.x, c.x, c.x) + Vector3(K.x, K.y, K.z)) * 6.0 - Vector3(K.w, K.w, K.w))
	return c.z * Vector3(K.x, K.x, K.x).lerp((p - Vector3(K.x, K.x, K.x)).clamp(Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0)), c.y)

# from can be: wheel, slider_r, slider_g, slider_b, slider_v, hex
func set_color_values(from: String, send_client_update = true):
	var col: Color
	match from:
		"wheel", "slider_v":
			var scaled_x = ((color_wheel_dot.position.x + wheel_dot_radius) - color_wheel.position.x) / 200
			var scaled_y = ((color_wheel_dot.position.y + wheel_dot_radius) - color_wheel.position.y) / 200
			var angle = atan2((scaled_y - 0.5), (scaled_x - 0.5))
			var radius = Vector2(scaled_x - 0.5, scaled_y - 0.5).length();
			var hue = (angle + PI) / (2 * PI);
			var saturation = radius * 2.0;
			var value = slider_v.value
			col = Color.from_hsv(hue, saturation, value)
			# set stuff
			slider_r.set_value_no_signal(col.r8)
			slider_g.set_value_no_signal(col.g8)
			slider_b.set_value_no_signal(col.b8)
		"slider_r", "slider_g", "slider_b":
			col = Color(slider_r.value / 255, slider_g.value / 255, slider_b.value / 255)
			var hue = col.h
			var saturation = col.s
			var value = col.v
			var angle = hue * 2.0 * PI - PI
			var radius = saturation / 2.0
			var scaled_x = 0.5 + radius * cos(angle)
			var scaled_y = 0.5 + radius * sin(angle)
			color_wheel_dot.position.x = 200 * scaled_x + color_wheel.position.x - wheel_dot_radius
			color_wheel_dot.position.y = 200 * scaled_y + color_wheel.position.y - wheel_dot_radius
			slider_v.set_value_no_signal(value)
			color_wheel.material.set_shader_parameter("value", value)
		"hex":
			col = Color(hex.text)
			var hue = col.h
			var saturation = col.s
			var value = col.v
			var angle = hue * 2.0 * PI - PI
			var radius = saturation / 2.0
			var scaled_x = 0.5 + radius * cos(angle)
			var scaled_y = 0.5 + radius * sin(angle)
			color_wheel_dot.position.x = 200 * scaled_x + color_wheel.position.x - wheel_dot_radius
			color_wheel_dot.position.y = 200 * scaled_y + color_wheel.position.y - wheel_dot_radius
			slider_v.set_value_no_signal(value)
			color_wheel.material.set_shader_parameter("value", value)
			slider_r.set_value_no_signal(col.r8)
			slider_g.set_value_no_signal(col.g8)
			slider_b.set_value_no_signal(col.b8)
	
	hex.text = "#%02X%02X%02X" % [col.r8, col.g8, col.b8]
	chosen_color.set_modulate(col)
	player.set_color(col)
	if send_client_update:
		queue_color_update()
	

var queue_timer: SceneTreeTimer = null
func queue_color_update():
	if queue_timer:
		return
	queue_timer = get_tree().create_timer(2.0, true, false, true)
	await queue_timer.timeout
	Client.update_user()
	queue_timer = null

func _on_color_wheel_dot_gui_input(event):
	if mouse_pressed_for_color_picker and event is InputEventMouseMotion:
		var new_pos = color_wheel_dot.position + event.relative
		var first_term = wheel_center.x - (new_pos.x + wheel_dot_radius)
		var second_term = wheel_center.y - (new_pos.y + wheel_dot_radius)
		if sqrt(first_term * first_term + second_term * second_term) < wheel_radius:
			color_wheel_dot.position = new_pos
			set_color_values("wheel")
		accept_event()
	if event is InputEventMouseButton:
		mouse_pressed_for_color_picker = event.pressed
		accept_event()

func _on_color_wheel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		color_wheel_dot.global_position = event.global_position
		set_color_values("wheel")

func _on_slider_r_value_changed(_value):
	set_color_values("slider_r")


func _on_slider_g_value_changed(_value):
	set_color_values("slider_g")


func _on_slider_b_value_changed(_value):
	set_color_values("slider_b")


func _on_slider_v_value_changed(value):
	color_wheel.material.set_shader_parameter("value", value)
	set_color_values("slider_v")


func _on_hex_text_submitted(_new_text, send_client_update = true):
	set_color_values("hex", send_client_update)
