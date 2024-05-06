extends Control

func change_count_or_delete(new_count: int):
	if new_count == 0:
		queue_free()
	else:
		$Count.text = str(new_count)
