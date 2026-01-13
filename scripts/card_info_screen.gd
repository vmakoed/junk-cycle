extends Control
class_name CardInfoScreen


signal close_button_pressed


enum Turn { CLEAR, ICE, HILL, TOURIST }
enum Item { HAIR_DRYER, FIRE_ALARM, BLENDER_MOTOR }


const TURN_TITLES : Dictionary[Turn, String] = {
	Turn.CLEAR: "Clear road",
	Turn.ICE: "Ice",
	Turn.HILL: "Hill",
	Turn.TOURIST: "Tourist"
}

const TURN_DESCRIPTIONS : Dictionary[Turn, String] = {
	Turn.CLEAR: "BOOST = normal distance.\nPEDAL = normal distance.",
	Turn.ICE: "BOOST = 0 distance (slip).\nPEDAL = normal distance.",
	Turn.HILL: "PEDAL = half distance.\nBOOST = normal.",
	Turn.TOURIST: "PEDAL = 0 distance.\nBOOST = normal."
}

const ITEM_TITLES: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "Hair dryer",
	Item.FIRE_ALARM: "Fire alarm",
	Item.BLENDER_MOTOR: "Blender motor"
}

const ITEM_DESCRIPTIONS: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "ICE: BOOST works normally",
	Item.FIRE_ALARM: "TOURIST: PEDAL works normally",
	Item.BLENDER_MOTOR: "HILL: PEDAL works normally"
}


@onready var cards_grid: GridContainer = %CardsGrid


func _ready() -> void:
	_assign_card(0, TURN_TITLES[Turn.ICE], TURN_DESCRIPTIONS[Turn.ICE])
	_assign_card(1, ITEM_TITLES[Item.HAIR_DRYER], ITEM_DESCRIPTIONS[Item.HAIR_DRYER])
	_assign_card(2, TURN_TITLES[Turn.TOURIST], TURN_DESCRIPTIONS[Turn.ICE])
	_assign_card(3, ITEM_TITLES[Item.FIRE_ALARM], ITEM_DESCRIPTIONS[Item.FIRE_ALARM])
	_assign_card(4, TURN_TITLES[Turn.HILL], TURN_DESCRIPTIONS[Turn.ICE])
	_assign_card(5, ITEM_TITLES[Item.BLENDER_MOTOR], ITEM_DESCRIPTIONS[Item.BLENDER_MOTOR])


func _assign_card(index: int, title_text: String, description_text: String) -> void:
	var container: HBoxContainer = cards_grid.get_child(index)
	var card: Card = container.get_child(0)
	var description: Label = container.get_child(1)
	card.title_text = title_text
	card.refresh()
	description.text = description_text


func _on_close_button_pressed() -> void:
	close_button_pressed.emit()
