extends Button
class_name CardToggleButton


const LABEL_TEXT = "Selected"
const LABEL_TEXTS: Dictionary[bool, String] = {
	true: "Selected",
	false: ""
}

const PANEL_CONTAINER_THEMES: Dictionary[bool, String] = {
	true: "CurrentTurnPanel",
	false: "PanelTransparent"
}


@onready var card: Card = %Card
@onready var label: Label = %Label
@onready var panel_container: PanelContainer = %PanelContainer


func _ready() -> void:
	_on_toggled(false)


func _on_toggled(toggled_on: bool) -> void:
	label.text = LABEL_TEXTS[toggled_on]
	panel_container.theme_type_variation = PANEL_CONTAINER_THEMES[toggled_on]
