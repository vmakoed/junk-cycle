extends Node


const DISTANCE_LABEL_TEXT = "Distance: {current_distance}/{distance_goal}m"
const BATTERY_LABEL_TEXT = "{current_battery}%"
const TURNS_LABEL_TEXT = "{current_turn}/{total_turns}"
const ACTION_INFO_DISTANCE_TEXT = "+{distance_change}m."
const ACTION_INFO_BATTERY_TEXT = "-{battery_change}% batt."
const WIN_TEXT = "You win!"
const GAME_OVER_TEXT = "Game over"


const DISTANCE_MIN = 0
const DISTANCE_GOAL = 1200
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
var selected_action: set = _set_selected_action
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

@onready var items_container: BoxContainer = %ItemsContainer
@onready var item_confirmed_button: Button = %ItemConfirmedButton

@onready var distance_label: Label = %DistanceLabel
@onready var battery_label: Label = %BatteryLabel
@onready var turns_label: Label = %TurnsLabel
@onready var distance_progress_bar: ProgressBar = %DistanceProgressBar
@onready var current_turn_title: Label = %CurrentTurnTitle
@onready var current_turn_description: Label= %CurrentTurnDescription
@onready var next_turn_cards: Array[Card] = [%NextTurnCard, %NextTurnCard2, %NextTurnCard3]
@onready var selected_item_card: Card = %SelectedItemCard
@onready var confirm_button: Button = %ConfirmButton

@onready var game_end_label: Label = %GameEndLabel


@onready var card_descriptions_button_container: MarginContainer = %CardDescriptionsButtonContainer
@onready var turn_descriptions_screen: PanelContainer = %TurnDescriptionsScreen
@onready var turn_descriptions_container: BoxContainer = %TurnDescriptionsContainer
@onready var item_descriptions_screen: PanelContainer = %ItemDescriptionsScreen
@onready var item_descriptions_container: BoxContainer = %ItemDescriptionsContainer


@onready var action_buttons: Dictionary[Action, Button] = {
	Action.PEDAL: %PedalButton,
	Action.BOOST: %BoostButton
} 


@onready var distance_labels : Dictionary[Action, Label] = {
	Action.PEDAL: action_buttons[Action.PEDAL].find_child("DistanceLabel"),
	Action.BOOST: action_buttons[Action.BOOST].find_child("DistanceLabel")
}

@onready var battery_labels : Dictionary[Action, Label] = {
	Action.PEDAL: action_buttons[Action.PEDAL].find_child("BatteryLabel"),
	Action.BOOST: action_buttons[Action.BOOST].find_child("BatteryLabel")
}


func _ready() -> void:
	_initialize_distance_progress_bar()
	_setup_item_cards()
	_setup_turn_descriptions()
	_setup_item_descriptions()
	card_descriptions_button_container.hide()


func _set_current_distance(new_value: int) -> void:
	current_distance = clamp(new_value, DISTANCE_MIN, DISTANCE_GOAL)

	_refresh_distance_label()
	_refresh_distance_progress_bar()
	if _is_goal_reached(): _on_goal_reached()


func _set_current_battery(new_value: int) -> void:
	current_battery = clamp(new_value, BATTERY_MIN, BATTERY_MAX)
	_refresh_battery_label()

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
		
	_refresh_turn_label()
	_refresh_turn_info()
	_refresh_action_info()
	_refresh_next_turns()


func _set_pedal_enabled(new_value: bool) -> void:
	pedal_enabled = new_value
	action_buttons[Action.PEDAL].disabled = not pedal_enabled

	if not pedal_enabled and selected_action == Action.PEDAL:
		action_buttons[Action.PEDAL].button_pressed = false


func _set_boost_enabled(new_value: bool) -> void:
	boost_enabled = new_value

	if not boost_enabled and selected_action == Action.BOOST:
		action_buttons[Action.BOOST].button_pressed = false

	action_buttons[Action.BOOST].disabled = not boost_enabled

	
func _set_selected_action(new_value) -> void:
	selected_action = new_value
	confirm_button.disabled = new_value == null


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


func _refresh_turn_label() -> void:
	turns_label.text = TURNS_LABEL_TEXT.format({
		"current_turn": current_turn + 1,
		"total_turns": turns.size()
	})


func _initialize_distance_progress_bar() -> void:
	distance_progress_bar.min_value = DISTANCE_MIN
	distance_progress_bar.max_value = DISTANCE_GOAL


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
		node.card.refresh()


func _setup_turn_descriptions() -> void:
	for item in Turn.values():
		var scene := load("res://scenes/card.tscn")
		var node := scene.instantiate() as Card
		turn_descriptions_container.add_child(node)
		node.title_text = TURN_TITLES[item]
		node.description_text = TURN_DESCRIPTIONS[item]
		node.refresh()


func _setup_item_descriptions() -> void:
	for item in Item.values():
		var scene := load("res://scenes/card.tscn")
		var node := scene.instantiate() as Card
		item_descriptions_container.add_child(node)
		node.title_text = ITEM_TITLES[item]
		node.description_text = ITEM_DESCRIPTIONS[item]
		node.refresh()


func _refresh_distance_progress_bar() -> void:
	distance_progress_bar.value = current_distance


func _refresh_turn_info() -> void:
	current_turn_title.text = TURN_TITLES[turns[current_turn]]
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
		else:
			next_turn_cards[next_turn_difference].title_text = TURN_TITLES[turns[next_turn]]
		
		next_turn_cards[next_turn_difference].refresh()


func _refresh_selected_item_card() -> void:
	selected_item_card.title_text = ITEM_TITLES[selected_item]
	selected_item_card.description_text = ITEM_DESCRIPTIONS[selected_item]
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
	card_descriptions_button_container.hide()
	game_end_container.show()
	
 
func _resolve_turn(movement: Action) -> void: 
	match movement:
		Action.PEDAL: 
			current_distance += distance_per_action[Action.PEDAL]
		Action.BOOST: 
			current_distance += distance_per_action[Action.BOOST]
			current_battery -= BATTERY_DRAIN_PER_ACTION[Action.BOOST]

	current_turn += TURNS_PER_MOVEMENT


func _assign_selected_action(action: Action, toggled_on: bool) -> void:
	if toggled_on:
		selected_action = action
	elif selected_action == action:
		selected_action = null


func _refresh_other_buttons(another_action: Action, toggled_on: bool) -> void:
	if toggled_on and action_buttons[another_action].button_pressed:
		action_buttons[another_action].button_pressed = false


func _on_pedal_button_toggled(toggled_on: bool) -> void:
	_assign_selected_action(Action.PEDAL, toggled_on)
	_refresh_other_buttons(Action.BOOST, toggled_on)


func _on_boost_button_toggled(toggled_on: bool) -> void:
	_assign_selected_action(Action.BOOST, toggled_on)
	_refresh_other_buttons(Action.PEDAL, toggled_on)


func _on_confirm_button_pressed() -> void:
	_resolve_turn(selected_action)


func _on_item_selection_changed(button: CardToggleButton) -> void:
	selected_item = Item[Item.keys()[button.get_index()]]


func _on_start_button_pressed() -> void:
	game_start_container.hide()
	item_selection_container.show()
	card_descriptions_button_container.show()


func _on_item_confirmed_button_pressed() -> void:
	item_selection_container.hide()
	_reset_state()
	level_container.show()


func _on_restart_button_pressed() -> void:
	level_container.hide()
	game_end_container.hide()
	item_selection_container.show()
	card_descriptions_button_container.show()


func _on_quit_button_pressed() -> void:
	level_container.hide()
	game_end_container.hide()
	game_start_container.show()


func _on_turn_descriptions_button_pressed() -> void:
	item_descriptions_screen.hide()
	turn_descriptions_screen.show()


func _on_turn_descriptions_close_button_pressed() -> void:
	turn_descriptions_screen.hide()


func _on_item_descriptions_button_pressed() -> void:
	turn_descriptions_screen.hide()
	item_descriptions_screen.show()


func _on_item_descriptions_close_button_pressed() -> void:
	item_descriptions_screen.hide()
