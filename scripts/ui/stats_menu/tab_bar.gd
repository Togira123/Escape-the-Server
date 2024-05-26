extends TabBar

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
