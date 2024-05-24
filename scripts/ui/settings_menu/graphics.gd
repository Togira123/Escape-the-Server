extends Control

@onready var environment: WorldEnvironment = $"/root/Main/WorldEnvironment"
@onready var light: DirectionalLight3D = $"/root/Main/DirectionalLight3D"
@onready var player_mesh: MeshInstance3D = $"/root/Main/Player/Armature/Skeleton3D/Skin"
@onready var level = $"/root/Main/Level"
@onready var radio_normal = $"RadioNormal"
@onready var radio_low = $"RadioLow"

const LOW_RES_FLOOR_MATERIAL = preload("res://assets/graphics/materials/LowResGroundMaterial.tres")
const NORMAL_RES_FLOOR_MATERIAL = preload("res://assets/graphics/materials/GroundMaterialCartoon.tres")

func _on_radio_normal_toggled(toggled_on: bool, update_settings = true):
	if toggled_on:
		environment.environment.set_glow_enabled(true)
		light.set_shadow(true)
		light.set_shadow_mode(2)
		player_mesh.set_cast_shadows_setting(1)
		player_mesh.set_gi_mode(1)
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
		light.set_shadow_mode(0)
		player_mesh.set_cast_shadows_setting(0)
		player_mesh.set_gi_mode(0)
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
