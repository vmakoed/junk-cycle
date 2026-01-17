extends Control
class_name Card


const IMAGE_PATH = "res://resources/{filename}.svg"


@export var title_text: String
@export var description_text: String
@export var image_filename: String


@onready var title: Label = %Title
@onready var image: TextureRect = %TextureRect
@onready var contents_container: VBoxContainer = %ContentsContainer


func _ready() -> void:
	refresh()


func refresh() -> void:
	title.text = title_text
	
	if image_filename:
		image.texture = load(IMAGE_PATH.format({
			"filename": image_filename
		}))
	else:
		image.texture = null

	contents_container.show()


func clear() -> void:
	title_text = ""
	description_text = ""
	image_filename = ""

	title.text = ""
	image.texture = null

	contents_container.hide()	
