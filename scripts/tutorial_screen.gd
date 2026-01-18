extends PanelContainer
class_name TutorialScreen


signal close_button_pressed
signal descriptions_button_pressed
signal ui_button_pressed


const PAGE_MIN = 0


@onready var pages: Control = %Pages
@onready var page_down_button: Button = %PageDownButton
@onready var page_up_button: Button = %PageUpButton


var current_page := 0: set = _set_current_page


func _ready() -> void:
	current_page = PAGE_MIN


func _set_current_page(new_value: int) -> void:
	pages.get_child(current_page).hide()
	current_page = new_value
	pages.get_child(current_page).show()
	page_down_button.disabled = current_page == PAGE_MIN
	page_up_button.disabled = current_page == pages.get_child_count() - 1


func _on_page_down_button_pressed() -> void:
	current_page -= 1


func _on_page_up_button_pressed() -> void:
	current_page += 1


func _on_close_button_pressed() -> void:
	close_button_pressed.emit()

func _on_ui_button_pressed() -> void:
	ui_button_pressed.emit()


func _on_descriptions_button_pressed() -> void:
	descriptions_button_pressed.emit()
