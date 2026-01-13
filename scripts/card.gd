extends Control
class_name Card


@export var title_text: String
@export var description_text: String


@onready var title: Label = %Title


func _ready() -> void:
	refresh()


func refresh() -> void:
	title.text = title_text
