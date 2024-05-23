extends Control

@onready var environment: WorldEnvironment = $"/root/Main/WorldEnvironment"
@onready var light: DirectionalLight3D = $"/root/Main/DirectionalLight3D"
@onready var player_mesh: MeshInstance3D = $"/root/Main/Player/Armature/Skeleton3D/Skin"
@onready var radio_normal = $"RadioNormal"
@onready var radio_low = $"RadioLow"

func _on_radio_normal_toggled(toggled_on: bool, update_settings = true):
	if toggled_on:
		environment.environment.set_glow_enabled(true)
		light.set_shadow(true)
		light.set_shadow_mode(2)
		player_mesh.set_cast_shadows_setting(1)
		player_mesh.set_gi_mode(1)
		if update_settings:
			radio_normal.set_pressed_no_signal(true)
			radio_low.set_pressed_no_signal(false)
			Client.settings["graphics_quality"] = 1
			Client.update_settings()

func _on_radio_low_toggled(toggled_on: bool, update_settings = true):
	if toggled_on:
		environment.environment.set_glow_enabled(false)
		light.set_shadow(false)
		light.set_shadow_mode(0)
		player_mesh.set_cast_shadows_setting(0)
		player_mesh.set_gi_mode(0)
		if update_settings:
			radio_low.set_pressed_no_signal(true)
			radio_normal.set_pressed_no_signal(false)
			Client.settings["graphics_quality"] = 0
			Client.update_settings()
