extends Control

@onready var player = $"../../../Player"
@onready var count = $Count

var change_count = true

func _process(delta: float) -> void:
	var cur_count = int(count.text)
	if change_count:
		if cur_count < player.material_count:
			cur_count += 1
		elif cur_count > player.material_count:
			cur_count -= 1
		count.text = str(cur_count)
	if player.material_count < 10:
		count.label_settings.font_color = Color.RED
	elif player.material_count < 40 or player.material_count == player.MAX_MATERIAL:
		count.label_settings.font_color = Color.ORANGE
	else:
		count.label_settings.font_color = Color.WHITE
	change_count = not change_count
