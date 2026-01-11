extends Control
class_name ToggleableCard


@export var toggleable: Toggleable


@onready var animation_player = %AnimationPlayer
@onready var card = %Card


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggleable.toggle_requested.emit()


func on_toggled() -> void:
	animation_player.play("toggle")


func on_untoggled() -> void:
	animation_player.play_backwards("toggle")
