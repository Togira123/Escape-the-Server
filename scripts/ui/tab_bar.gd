extends TabBar

func _gui_input(event):
	if event is InputEventKey and event.pressed:
		print(current_tab)
		match event.keycode:
			KEY_ESCAPE:
				# ignore escape as it will close the whole thing in the Help rect script
				return
			KEY_LEFT:
				if current_tab > 0:
					set_current_tab(current_tab - 1)
			KEY_RIGHT:
				if current_tab < tab_count - 1:
					set_current_tab(current_tab + 1)
		accept_event()
