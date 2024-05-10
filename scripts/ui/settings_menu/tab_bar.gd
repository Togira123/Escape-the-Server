extends TabBar

func _gui_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				# ignore escape as it will close the whole thing in the Help rect script
				return
			KEY_LEFT:
				switch_to_left()
			KEY_RIGHT:
				switch_to_right()
		accept_event()

func switch_to_left():
	if current_tab > 0:
		set_current_tab(current_tab - 1)
	else:
		set_current_tab(tab_count - 1)

func switch_to_right():
	if current_tab < tab_count - 1:
		set_current_tab(current_tab + 1)
	else:
		set_current_tab(0)


func _on_arrow_left_pressed():
	switch_to_left()

func _on_arrow_right_pressed():
	switch_to_right()
