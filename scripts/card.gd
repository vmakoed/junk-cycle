extends Control
class_name Card


const IMAGE_PATH = "res://resources/{filename}.svg"


@export var title_text: String
@export var description_text: String
@export var image_filename: String


@onready var title: Label = %Title
@onready var image: TextureRect = %TextureRect


func _ready() -> void:
	refresh()


func refresh() -> void:
	title.text = title_text
	image.texture = load(IMAGE_PATH.format({
		"filename": image_filename
	}))
