extends Control

@onready var environment: WorldEnvironment = $"/root/Main/WorldEnvironment"
@onready var light: DirectionalLight3D = $"/root/Main/DirectionalLight3D"
@onready var player_mesh: MeshInstance3D = $"/root/Main/Player/Armature/Skeleton3D/Skin"
@onready var level = $"/root/Main/Level"
@onready var radio_normal = $"RadioNormal"
@onready var radio_low = $"RadioLow"
@onready var volume_value = $VolumeValue
@onready var volume_slider = $VolumeSlider

const LOW_RES_FLOOR_MATERIAL = preload("res://assets/graphics/materials/LowResGroundMaterial.tres")
const NORMAL_RES_FLOOR_MATERIAL = preload("res://assets/graphics/materials/GroundMaterialCartoon.tres")

func _on_radio_normal_toggled(toggled_on: bool, update_settings = true):
	if toggled_on:
		environment.environment.set_glow_enabled(true)
		light.set_shadow(true)
		light.set_shadow_mode(DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
		player_mesh.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
		player_mesh.set_gi_mode(GeometryInstance3D.GI_MODE_STATIC)
		if update_settings:
			for inst in level.loaded_modules:
				if not inst:
					break
				inst.get_node("Ground/Floor").mesh.surface_set_material(0, NORMAL_RES_FLOOR_MATERIAL)
			Client.settings["graphics_quality"] = 1
			Client.update_settings()
		else:
			# in this case the function was called in ready() of the main_menu script
			radio_normal.set_pressed_no_signal(true)
			radio_low.set_pressed_no_signal(false)

func _on_radio_low_toggled(toggled_on: bool, update_settings = true):
	if toggled_on:
		environment.environment.set_glow_enabled(false)
		light.set_shadow(false)
		light.set_shadow_mode(DirectionalLight3D.SHADOW_ORTHOGONAL)
		player_mesh.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		player_mesh.set_gi_mode(GeometryInstance3D.GI_MODE_DISABLED)
		if update_settings:
			for inst in level.loaded_modules:
				if not inst:
					break
				inst.get_node("Ground/Floor").mesh.surface_set_material(0, LOW_RES_FLOOR_MATERIAL)
			Client.settings["graphics_quality"] = 0
			Client.update_settings()
		else:
			# in this case the function was called in ready() of the main_menu script
			radio_low.set_pressed_no_signal(true)
			radio_normal.set_pressed_no_signal(false)

var queue_timer: SceneTreeTimer = null
func queue_volume_setting_change():
	if queue_timer:
		return
	queue_timer = get_tree().create_timer(2.0, true, false, true)
	await queue_timer.timeout
	Client.update_settings()
	queue_timer = null

func _on_volume_slider_value_changed(value, update_settings = true):
	volume_value.text = str(value)
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	AudioServer.set_bus_mute(0, value < 0.05)
	if update_settings:
		Client.settings["master_volume"] = value
		queue_volume_setting_change()
	else:
		volume_slider.set_value_no_signal(value)
