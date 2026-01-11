extends Node


const DISTANCE_LABEL_TEXT = "Distance: {current_distance}/{distance_goal}m"
const BATTERY_LABEL_TEXT = "{current_battery}%"
const TURNS_LABEL_TEXT = "{current_turn}/{total_turns}"
const ACTION_INFO_DISTANCE_TEXT = "+{distance_change}m dist."
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
	Turn.ICE: "Icy road",
	Turn.HILL: "Hill",
	Turn.TOURIST: "Tourist"
}

const TURN_DESCRIPTIONS : Dictionary[Turn, String] = {
	Turn.CLEAR: "A biker's dream! Continue as usual.",
	Turn.ICE: "Frozen precipitation. You will slip if you boost and move zero distance.",
	Turn.HILL: "Too many leg days skipped! Pedalling moves half the usual distance.",
	Turn.TOURIST: "Tourist is approaching! Speed up or wait for them to cross. Pedalling moves zero distance."
}

const ITEM_TITLES: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "Hair dryer",
	Item.FIRE_ALARM: "Fire alarm",
	Item.BLENDER_MOTOR: "Blender motor"
}

const ITEM_DESCRIPTIONS: Dictionary[Item, String] = {
	Item.HAIR_DRYER: "BOOST through ICE without penalties",
	Item.FIRE_ALARM: "PEDAL through TOURIST without penalties",
	Item.BLENDER_MOTOR: "PEDAL through HILL without penalties"
}

const distances_per_pedal: Dictionary[Turn, int] = {
	Turn.CLEAR: 50,
	Turn.ICE: 50,
	Turn.HILL: 25,
	Turn.TOURIST: 0
}

const distances_per_boost: Dictionary[Turn, int] = {
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
@onready var level_container: PanelContainer = %LevelContainer
@onready var game_end_container: PanelContainer = %GameEndContainer

@onready var items_container: BoxContainer = %ItemsContainer

@onready var distance_label: Label = %DistanceLabel
@onready var battery_label: Label = %BatteryLabel
@onready var turns_label: Label = %TurnsLabel
@onready var distance_progress_bar: ProgressBar = %DistanceProgressBar
@onready var current_turn_title: Label = %CurrentTurnTitle
@onready var current_turn_description: Label= %CurrentTurnDescription
@onready var next_TURN_TITLES: Array[Label] = [%NextTurnTitle, %NextTurnTitle2, %NextTurnTitle3]
@onready var selected_item_card: Card = %SelectedItemCard
@onready var confirm_button: Button = %ConfirmButton

@onready var game_end_label: Label = %GameEndLabel


@onready var action_buttons: Dictionary[Action, Button] = {
	Action.PEDAL: %PedalButton,
	Action.BOOST: %BoostButton
} 

@onready var action_info_containers: Dictionary[Action, PanelContainer] = {
	Action.PEDAL: %PedalInfo,
	Action.BOOST: %BoostInfo
}

@onready var action_animation_players : Dictionary[Action, AnimationPlayer] = {
	Action.PEDAL: action_buttons[Action.PEDAL].find_child("AnimationPlayer"),
	Action.BOOST: action_buttons[Action.BOOST].find_child("AnimationPlayer")
}

@onready var info_animation_players : Dictionary[Action, AnimationPlayer] = {
	Action.PEDAL: action_info_containers[Action.PEDAL].find_child("AnimationPlayer"),
	Action.BOOST: action_info_containers[Action.BOOST].find_child("AnimationPlayer")
}

@onready var distance_labels : Dictionary[Action, Label] = {
	Action.PEDAL: action_info_containers[Action.PEDAL].find_child("DistanceLabel"),
	Action.BOOST: action_info_containers[Action.BOOST].find_child("DistanceLabel")
}

@onready var battery_labels : Dictionary[Action, Label] = {
	Action.PEDAL: action_info_containers[Action.PEDAL].find_child("BatteryLabel"),
	Action.BOOST: action_info_containers[Action.BOOST].find_child("BatteryLabel")
}


func _ready() -> void:
	_initialize_distance_progress_bar()
	_setup_cards()
	_setup_card_selection_events()
	_reset_state()


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

	if not pedal_enabled && selected_action == Action.PEDAL:
		action_buttons[Action.PEDAL].button_pressed = false


func _set_boost_enabled(new_value: bool) -> void:
	boost_enabled = new_value

	if not boost_enabled && selected_action == Action.BOOST:
		action_buttons[Action.BOOST].button_pressed = false

	action_buttons[Action.BOOST].disabled = not boost_enabled

	
func _set_selected_action(new_value) -> void:
	selected_action = new_value
	confirm_button.disabled = new_value == null


func _set_selected_item(new_value) -> void:
	selected_item = new_value
	_refresh_selected_item_card()


func _reset_state() -> void:
	current_distance = DISTANCE_MIN
	current_battery = BATTERY_MAX
	current_turn = TURNS_MIN


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


func _setup_cards() -> void:
	for item in Item.values():
		var scene := load("res://scenes/card.tscn")
		var node := scene.instantiate() as Card
		items_container.add_child(node)
		node.title_text = ITEM_TITLES[item]
		node.description_text = ITEM_DESCRIPTIONS[item]
		node.refresh()


func _setup_card_selection_events() -> void:
	items_container.toggled_child_changed.connect(_on_item_selection_changed)


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
	for next_turn_difference in next_TURN_TITLES.size():
		var next_turn := current_turn + 1 + next_turn_difference
		if next_turn >= turns.size():
			next_TURN_TITLES[next_turn_difference].text = ""
		else:
			next_TURN_TITLES[next_turn_difference].text = TURN_TITLES[turns[next_turn]]


func _refresh_selected_item_card() -> void:
	print(selected_item)
	print(ITEM_DESCRIPTIONS)
	selected_item_card.title_text = ITEM_TITLES[selected_item]
	selected_item_card.description_text = ITEM_DESCRIPTIONS[selected_item]
	selected_item_card.refresh()


func _apply_turn_effects() -> void:
	distance_per_action[Action.PEDAL] = distances_per_pedal[turns[current_turn]]
	distance_per_action[Action.BOOST] = distances_per_boost[turns[current_turn]]


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
	match movement:
		Action.PEDAL: 
			current_distance += distance_per_action[Action.PEDAL]
		Action.BOOST: 
			current_distance += distance_per_action[Action.BOOST]
			current_battery -= BATTERY_DRAIN_PER_ACTION[Action.BOOST]

	current_turn += TURNS_PER_MOVEMENT


func _play_action_animations(action: Action, toggled_on: bool) -> void:
	if toggled_on:
		action_animation_players[action].play("toggle")
		info_animation_players[action].play("appear")
	else:
		info_animation_players[action].play_backwards("appear")
		action_animation_players[action].play_backwards("toggle")


func _assign_selected_action(action: Action, toggled_on: bool) -> void:
	if toggled_on:
		selected_action = action
	elif selected_action == action:
		selected_action = null


func _refresh_other_buttons(another_action: Action, toggled_on: bool) -> void:
	if toggled_on && action_buttons[another_action].button_pressed:
		action_buttons[another_action].button_pressed = false


func _on_pedal_button_toggled(toggled_on: bool) -> void:
	_assign_selected_action(Action.PEDAL, toggled_on)
	_refresh_other_buttons(Action.BOOST, toggled_on)
	_play_action_animations(Action.PEDAL, toggled_on)


func _on_boost_button_toggled(toggled_on: bool) -> void:
	_assign_selected_action(Action.BOOST, toggled_on)
	_refresh_other_buttons(Action.PEDAL, toggled_on)
	_play_action_animations(Action.BOOST, toggled_on)


func _on_confirm_button_pressed() -> void:
	_resolve_turn(selected_action)


func _on_item_selection_changed(item: Card) -> void:
	selected_item = Item[Item.keys()[item.get_index()]]


func _on_start_button_pressed() -> void:
	game_start_container.hide()
	item_selection_container.show()


func _on_item_confirmed_button_pressed() -> void:
	item_selection_container.hide()
	level_container.show()


func _on_restart_button_pressed() -> void:
	_reset_state()
	game_end_container.hide()
	item_selection_container.show()


func _on_quit_button_pressed() -> void:
	game_end_container.hide()
	game_start_container.show()
