extends Control
class_name Card


@export var title_text: String
@export var description_text: String
@export var toggleable: Toggleable


@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var animation_player = %AnimationPlayer


func _ready() -> void:
	refresh()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			toggleable.toggle_requested.emit()


func on_toggled() -> void:
	animation_player.play("toggle")


func on_untoggled() -> void:
	animation_player.play_backwards("toggle")


func refresh() -> void:
	title.text = title_text
	description.text = description_text
