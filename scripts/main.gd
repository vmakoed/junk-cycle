extends Node


const DISTANCE_LABEL_TEXT = "Distance: {current_distance}/{distance_goal}m"
const BATTERY_LABEL_TEXT = "{current_battery}%"
const TURNS_LABEL_TEXT = "{turns_left}/{total_turns}"
const ACTION_INFO_DISTANCE_TEXT = "+{distance_change}m."
const ACTION_INFO_BATTERY_TEXT = "-{battery_change}% batt."
const WIN_TEXT = "You win!"
const GAME_OVER_TEXT = "Game over"


const DISTANCE_MIN = 0
const DISTANCE_GOAL = 1500
const BATTERY_MAX = 100
const BATTERY_MIN = 0
const TURNS_MIN = 0
const TURNS_PER_MOVEMENT = 1


enum Turn { CLEAR, ICE, HILL, TOURIST }
enum Action { PEDAL, BOOST }
enum Item { HAIR_DRYER, FIRE_ALARM, BLENDER_MOTOR }


const TURN_TITLES : Dictionary[Turn, String] = {
	Turn.CLEAR: "Clear road",
	Turn.ICE: "Ice",
	Turn.HILL: "Hill",
	Turn.TOURIST: "Tourist"
}

const TURN_DESCRIPTIONS : Dictionary[Turn, String] = {
	Turn.CLEAR: "BOOST = normal distance. PEDAL = normal distance.",
	Turn.ICE: "BOOST = 0 distance (slip). PEDAL = normal distance.",
	Turn.HILL: "PEDAL = half distance. BOOST = normal.",
	Turn.TOURIST: "PEDAL = 0 distance. BOOST = normal."
}

const TURN_IMAGES: Dictionary[Turn, String] = {
	Turn.CLEAR: "trail",
	Turn.ICE: "snowflake-2",
	Turn.HILL: "hills",
	Turn.TOURIST: "walk"
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

const ITEM_IMAGES: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "computer-fan",
	Item.FIRE_ALARM: "movement-sensor",
	Item.BLENDER_MOTOR: "blender"
}

const DISTANCES_PER_PEDAL: Dictionary[Turn, int] = {
	Turn.CLEAR: 50,
	Turn.ICE: 50,
	Turn.HILL: 25,
	Turn.TOURIST: 0
}

const DISTANCES_PER_BOOST: Dictionary[Turn, int] = {
	Turn.CLEAR: 100,
	Turn.ICE: 0,
	Turn.HILL: 100,
	Turn.TOURIST: 100
}

const BATTERY_DRAIN_PER_ACTION: Dictionary[Action, int] = {
	Action.PEDAL: 0,
	Action.BOOST: 10
}


var current_distance: int: set = _set_current_distance  
var current_battery: int: set = _set_current_battery
var current_turn: int: set = _set_current_turn
var pedal_enabled: bool: set = _set_pedal_enabled
var boost_enabled: bool: set = _set_boost_enabled
var selected_item: set = _set_selected_item
var items_button_group : ButtonGroup
var distance_per_action: Dictionary[Action, int]


var turns : Array[Turn] = [
	Turn.CLEAR, 	# 0
	Turn.CLEAR,		# 1
	Turn.ICE,		# 2
	Turn.CLEAR,		# 3
	Turn.HILL, 		# 4
	Turn.TOURIST,	# 5
	Turn.CLEAR,		# 6
	Turn.CLEAR,		# 7
	Turn.ICE,		# 8
	Turn.CLEAR, 	# 9
	Turn.HILL,		# 10
	Turn.TOURIST,	# 11
	Turn.CLEAR,		# 12
	Turn.CLEAR,		# 13
	Turn.ICE, 		# 14
	Turn.CLEAR,		# 15
	Turn.HILL,		# 16
	Turn.TOURIST,	# 17
	Turn.CLEAR,		# 18
	Turn.CLEAR, 	# 19
]


@onready var game_start_container: PanelContainer = %GameStartContainer
@onready var item_selection_container: PanelContainer = %ItemSelectionContainer
@onready var level_container: Control = %LevelContainer
@onready var game_end_container: PanelContainer = %GameEndContainer
@onready var card_info_screen: CardInfoScreen = %CardInfoScreen

@onready var items_container: BoxContainer = %ItemsContainer
@onready var item_confirmed_button: Button = %ItemConfirmedButton

@onready var distance_label: Label = %DistanceLabel

@onready var battery_label: Label = %BatteryLabel
@onready var battery_progress_bar: ProgressBar = %BatteryProgressBar

@onready var turns_label: Label = %TurnsLabel
@onready var turns_progress_bar: ProgressBar = %TurnsProgressBar

@onready var distance_progress_bar: ProgressBar = %DistanceProgressBar
@onready var current_turn_card: Card = %CurrentTurnCard
@onready var current_turn_description: Label= %CurrentTurnDescription
@onready var next_turn_cards: Array[Card] = [%NextTurnCard, %NextTurnCard2, %NextTurnCard3]
@onready var selected_item_card: Card = %SelectedItemCard
@onready var confirm_button: Button = %ConfirmButton

@onready var game_end_label: Label = %GameEndLabel

@onready var action_buttons: Dictionary[Action, Button] = {
	Action.PEDAL: %PedalButton,
	Action.BOOST: %BoostButton
} 

@onready var action_containers: Dictionary[Action, BoxContainer] = {
	Action.PEDAL: %PedalContainer,
	Action.BOOST: %BoostContainer
}

@onready var distance_labels : Dictionary[Action, Label] = {
	Action.PEDAL: action_containers[Action.PEDAL].find_child("DistanceLabel"),
	Action.BOOST: action_containers[Action.BOOST].find_child("DistanceLabel")
}

@onready var battery_labels : Dictionary[Action, Label] = {
	Action.PEDAL: action_containers[Action.PEDAL].find_child("BatteryLabel"),
	Action.BOOST: action_containers[Action.BOOST].find_child("BatteryLabel")
}


func _ready() -> void:
	_initialize_progress_bars()
	_setup_item_cards()


func _set_current_distance(new_value: int) -> void:
	current_distance = clamp(new_value, DISTANCE_MIN, DISTANCE_GOAL)

	_refresh_distance_label()
	_refresh_distance_progress_bar()
	if _is_goal_reached(): _on_goal_reached()


func _set_current_battery(new_value: int) -> void:
	current_battery = clamp(new_value, BATTERY_MIN, BATTERY_MAX)
	_refresh_battery_label()
	_refresh_battery_progress_bar()

	if _is_goal_reached(): return
	if (current_battery < BATTERY_DRAIN_PER_ACTION[Action.BOOST]):
		boost_enabled = false
	else:
		boost_enabled = true


func _set_current_turn(new_value: int) -> void:
	if new_value == turns.size():
		_on_out_of_turns()
	else:
		current_turn = clamp(new_value, TURNS_MIN, turns.size() - 1)
		_apply_turn_effects()
		
	_refresh_turns_label()
	_refresh_turns_progress_bar()
	_refresh_turn_info()
	_refresh_action_info()
	_refresh_next_turns()


func _set_pedal_enabled(new_value: bool) -> void:
	pedal_enabled = new_value
	action_buttons[Action.PEDAL].disabled = not pedal_enabled


func _set_boost_enabled(new_value: bool) -> void:
	boost_enabled = new_value
	action_buttons[Action.BOOST].disabled = not boost_enabled


func _set_selected_item(new_value) -> void:
	selected_item = new_value
	item_confirmed_button.disabled = selected_item == null
	if selected_item != null: _refresh_selected_item_card()


func _reset_state() -> void:
	current_distance = DISTANCE_MIN
	current_battery = BATTERY_MAX
	current_turn = TURNS_MIN
	pedal_enabled = true


func _is_goal_reached() -> bool:
	return current_distance == DISTANCE_GOAL


func _refresh_distance_label() -> void:
	distance_label.text = DISTANCE_LABEL_TEXT.format({
		"current_distance": current_distance,
		"distance_goal": DISTANCE_GOAL
	})


func _refresh_battery_label() -> void:
	battery_label.text = BATTERY_LABEL_TEXT.format({
		"current_battery": current_battery
	})


func _refresh_turns_label() -> void:
	turns_label.text = TURNS_LABEL_TEXT.format({
		"turns_left": _turns_left(),
		"total_turns": turns.size()
	})


func _turns_left() -> int:
	return turns.size() - current_turn


func _initialize_progress_bars() -> void:
	distance_progress_bar.min_value = DISTANCE_MIN
	distance_progress_bar.max_value = DISTANCE_GOAL
	turns_progress_bar.max_value = turns.size()
	turns_progress_bar.min_value = TURNS_MIN
	battery_progress_bar.max_value = BATTERY_MAX
	battery_progress_bar.min_value = BATTERY_MIN


func _setup_item_cards() -> void:
	items_button_group = ButtonGroup.new()
	items_button_group.pressed.connect(_on_item_selection_changed)

	for item in Item.values():
		var scene := load("res://scenes/card_toggle_button.tscn")
		var node := scene.instantiate() as CardToggleButton
		items_container.add_child(node)
		node.button_group = items_button_group
		node.card.title_text = ITEM_TITLES[item]
		node.card.description_text = ITEM_DESCRIPTIONS[item]
		node.card.image_filename = ITEM_IMAGES[item]
		node.card.refresh()


func _refresh_distance_progress_bar() -> void:
	distance_progress_bar.value = current_distance


func _refresh_battery_progress_bar() -> void:
	battery_progress_bar.value = current_battery


func _refresh_turns_progress_bar() -> void:
	turns_progress_bar.value = _turns_left()


func _refresh_turn_info() -> void:
	current_turn_card.title_text = TURN_TITLES[turns[current_turn]]
	current_turn_card.image_filename = TURN_IMAGES[turns[current_turn]]
	current_turn_card.refresh()
	current_turn_description.text = TURN_DESCRIPTIONS[turns[current_turn]]


func _refresh_action_info() -> void:
	for action in Action.values():
		distance_labels[action].text = ACTION_INFO_DISTANCE_TEXT.format(
			{ "distance_change": distance_per_action[action] }
		)
		battery_labels[action].text = ACTION_INFO_BATTERY_TEXT.format(
			{ "battery_change": BATTERY_DRAIN_PER_ACTION[action] }
		)


func _refresh_next_turns() -> void:
	for next_turn_difference in next_turn_cards.size():
		var next_turn := current_turn + 1 + next_turn_difference

		if next_turn >= turns.size():
			next_turn_cards[next_turn_difference].title_text = ""
			next_turn_cards[next_turn_difference].image_filename = ""
		else:
			next_turn_cards[next_turn_difference].title_text = TURN_TITLES[turns[next_turn]]
			next_turn_cards[next_turn_difference].image_filename = TURN_IMAGES[turns[next_turn]]
		
		next_turn_cards[next_turn_difference].refresh()


func _refresh_selected_item_card() -> void:
	selected_item_card.title_text = ITEM_TITLES[selected_item]
	selected_item_card.description_text = ITEM_DESCRIPTIONS[selected_item]
	selected_item_card.image_filename = ITEM_IMAGES[selected_item]
	selected_item_card.refresh()


func _apply_turn_effects() -> void:
	_apply_pedal_effect()
	_apply_boost_effect()


func _apply_pedal_effect() -> void:
	if (selected_item == Item.FIRE_ALARM and turns[current_turn] == Turn.TOURIST) or \
		(selected_item == Item.BLENDER_MOTOR and turns[current_turn] == Turn.HILL):
			distance_per_action[Action.PEDAL] = DISTANCES_PER_PEDAL[Turn.CLEAR]
	else:
		distance_per_action[Action.PEDAL] = DISTANCES_PER_PEDAL[turns[current_turn]]


func _apply_boost_effect() -> void:
	if (selected_item == Item.HAIR_DRYER and turns[current_turn] == Turn.ICE):
		distance_per_action[Action.BOOST] = DISTANCES_PER_BOOST[Turn.CLEAR]
	else:
		distance_per_action[Action.BOOST] = DISTANCES_PER_BOOST[turns[current_turn]]


func _on_out_of_turns() -> void:
	if current_distance < DISTANCE_GOAL:
		game_end_label.text = GAME_OVER_TEXT

	_on_final_turn_played()


func _on_goal_reached() -> void:
	game_end_label.text = WIN_TEXT
	_on_final_turn_played()


func _on_final_turn_played() -> void:
	pedal_enabled = false
	boost_enabled = false
	game_end_container.show()
	
 
func _resolve_turn(movement: Action) -> void: 
	current_distance += distance_per_action[movement]
	current_battery -= BATTERY_DRAIN_PER_ACTION[movement]
	current_turn += TURNS_PER_MOVEMENT


func _on_pedal_button_pressed() -> void:
	_resolve_turn(Action.PEDAL)


func _on_boost_button_pressed() -> void:
	_resolve_turn(Action.BOOST)


func _on_item_selection_changed(button: CardToggleButton) -> void:
	selected_item = Item[Item.keys()[button.get_index()]]


func _on_start_button_pressed() -> void:
	game_start_container.hide()
	item_selection_container.show()


func _on_item_confirmed_button_pressed() -> void:
	item_selection_container.hide()
	_reset_state()
	level_container.show()


func _on_restart_button_pressed() -> void:
	level_container.hide()
	game_end_container.hide()
	item_selection_container.show()


func _on_quit_button_pressed() -> void:
	level_container.hide()
	game_end_container.hide()
	game_start_container.show()


func _on_descriptions_button_pressed() -> void:
	card_info_screen.show()


func _on_card_info_screen_close_button_pressed() -> void:
	card_info_screen.hide()
