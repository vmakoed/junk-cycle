extends PanelContainer
class_name CardPanel


@onready var card: Card = %Card
@onready var description: Label = %Description


func refresh() -> void:
	card.refresh()
	description.text = card.description_text
