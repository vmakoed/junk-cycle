extends Control
class_name CardInfoScreen


signal close_button_pressed


enum Turn { CLEAR, ICE, HILL, TOURIST }
enum Item { HAIR_DRYER, FIRE_ALARM, BLENDER_MOTOR }


const CARDS_COUNT = 6


const TURN_TITLES : Dictionary[Turn, String] = {
	Turn.CLEAR: "Clear road",
	Turn.ICE: "Ice",
	Turn.HILL: "Hill",
	Turn.TOURIST: "Tourist"
}

const TURN_IMAGES: Dictionary[Turn, String] = {
	Turn.CLEAR: "trail",
	Turn.ICE: "snowflake-2",
	Turn.HILL: "hills",
	Turn.TOURIST: "walk"
}

const TURN_DESCRIPTIONS : Dictionary[Turn, String] = {
	Turn.CLEAR: "Nothing blocking your path - just you, your battery, and the distance ahead.",
	Turn.ICE: "Ice patches force you to slow down. If you try to BOOST through ice, you'll slip and skid without moving this turn.",
	Turn.HILL: "Steep inclines demand power. BOOSTing works normally, but if you try to PEDAL, you'll barely crawl forward.",
	Turn.TOURIST: "Oblivious pedestrians approaching! If you PEDAL, you'll have to stop completely - wasting your turn. BOOST before it's too late."
}

const ITEM_TITLES: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "Hair dryer",
	Item.FIRE_ALARM: "Fire alarm",
	Item.BLENDER_MOTOR: "Blender motor"
}

const ITEM_DESCRIPTIONS: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "Hair dryer's heat melts through ICE patches, letting you BOOST straight through them at full speed.",
	Item.FIRE_ALARM: "Alarm's piercing shriek scares pedestrians out of your way. You do not have to stop if you choose to PEDAL.",
	Item.BLENDER_MOTOR: "The blender motor's industrial torque powers through inclines effortlessly. PEDAL through hills at full distance."
}

const ITEM_IMAGES: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "computer-fan",
	Item.FIRE_ALARM: "movement-sensor",
	Item.BLENDER_MOTOR: "blender"
}

@onready var cards_grid: GridContainer = %CardsGrid


func _ready() -> void:
	_create_cards()
	_assign_card(0, TURN_TITLES[Turn.ICE], TURN_DESCRIPTIONS[Turn.ICE], TURN_IMAGES[Turn.ICE])
	_assign_card(1, ITEM_TITLES[Item.HAIR_DRYER], ITEM_DESCRIPTIONS[Item.HAIR_DRYER], ITEM_IMAGES[Item.HAIR_DRYER])
	_assign_card(2, TURN_TITLES[Turn.TOURIST], TURN_DESCRIPTIONS[Turn.TOURIST], TURN_IMAGES[Turn.TOURIST])
	_assign_card(3, ITEM_TITLES[Item.FIRE_ALARM], ITEM_DESCRIPTIONS[Item.FIRE_ALARM], ITEM_IMAGES[Item.FIRE_ALARM])
	_assign_card(4, TURN_TITLES[Turn.HILL], TURN_DESCRIPTIONS[Turn.HILL], TURN_IMAGES[Turn.HILL])
	_assign_card(5, ITEM_TITLES[Item.BLENDER_MOTOR], ITEM_DESCRIPTIONS[Item.BLENDER_MOTOR], ITEM_IMAGES[Item.BLENDER_MOTOR])


func _create_cards() -> void:
	for card_index in CARDS_COUNT:
		var scene := load("res://scenes/card_horizontal.tscn")
		var node := scene.instantiate() as CardHorizontal
		cards_grid.add_child(node)

func _assign_card(index: int, title_text: String, description_text: String, image_filename: String) -> void:
	var container: HBoxContainer = cards_grid.get_child(index).get_child(0)
	var card: Card = container.get_child(0)
	var description: Label = container.get_child(1).get_child(0)
	card.title_text = title_text
	card.image_filename = image_filename
	card.refresh()
	description.text = description_text


func _on_close_button_pressed() -> void:
	close_button_pressed.emit()
