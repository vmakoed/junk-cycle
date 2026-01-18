extends PanelContainer
class_name OptionsScreen


signal tutorial_button_pressed
signal restart_button_pressed
signal quit_button_pressed
signal close_button_pressed


func _on_tutorial_button_pressed() -> void:
	tutorial_button_pressed.emit()


func _on_restart_button_pressed() -> void:
	restart_button_pressed.emit()


func _on_quit_button_pressed() -> void:
	quit_button_pressed.emit()


func _on_close_button_pressed() -> void:
	close_button_pressed.emit()
