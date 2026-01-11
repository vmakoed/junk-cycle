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


const turn_titles : Dictionary[Turn, String] = {
	Turn.CLEAR: "Clear road",
	Turn.ICE: "Black ice",
	Turn.HILL: "Hill",
	Turn.TOURIST: "Tourist"
}

const turn_descriptions : Dictionary[Turn, String] = {
	Turn.CLEAR: "A biker's dream! Continue as usual.",
	Turn.ICE: "Frozen precipitation. You will slip if you boost and move zero distance.",
	Turn.HILL: "Too many leg days skipped! Pedalling moves half the usual distance.",
	Turn.TOURIST: "Tourist is approaching! Speed up or wait for them to cross. Pedalling moves zero distance."
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


var current_distance : int : set = _set_current_distance  
var current_battery : int : set = _set_current_battery
var current_turn : int : set = _set_current_turn
var pedal_enabled : bool : set = _set_pedal_enabled
var boost_enabled : bool : set = _set_boost_enabled
var selected_action: set = _set_selected_action
var distance_per_action : Dictionary[Action, int]


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


@onready var distance_label : Label = %DistanceLabel
@onready var battery_label : Label = %BatteryLabel
@onready var turns_label : Label = %TurnsLabel
@onready var distance_progress_bar : ProgressBar = %DistanceProgressBar
@onready var current_turn_title : Label = %CurrentTurnTitle
@onready var current_turn_description : Label= %CurrentTurnDescription
@onready var next_turn_titles : Array[Label] = [%NextTurnTitle, %NextTurnTitle2, %NextTurnTitle3]
@onready var confirm_button: Button = %ConfirmButton
@onready var game_end_container: PanelContainer = %GameEndContainer
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


func _refresh_distance_progress_bar() -> void:
	distance_progress_bar.value = current_distance


func _refresh_turn_info() -> void:
	current_turn_title.text = turn_titles[turns[current_turn]]
	current_turn_description.text = turn_descriptions[turns[current_turn]]


func _refresh_action_info() -> void:
	for action in Action.values():
		distance_labels[action].text = ACTION_INFO_DISTANCE_TEXT.format(
			{ "distance_change": distance_per_action[action] }
		)
		battery_labels[action].text = ACTION_INFO_BATTERY_TEXT.format(
			{ "battery_change": BATTERY_DRAIN_PER_ACTION[action] }
		)

func _refresh_next_turns() -> void:
	for next_turn_difference in next_turn_titles.size():
		var next_turn := current_turn + 1 + next_turn_difference
		if next_turn >= turns.size():
			next_turn_titles[next_turn_difference].text = ""
		else:
			next_turn_titles[next_turn_difference].text = turn_titles[turns[next_turn]]


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


func _play_action_button_animation(action: Action, toggled_on: bool) -> void:
	if toggled_on:
		action_animation_players[action].play("toggle")
		info_animation_players[action].play("appear")
	else:
		action_animation_players[action].play_backwards("toggle")
		info_animation_players[action].play_backwards("appear")


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
	_play_action_button_animation(Action.PEDAL, toggled_on)


func _on_boost_button_toggled(toggled_on: bool) -> void:
	_assign_selected_action(Action.BOOST, toggled_on)
	_refresh_other_buttons(Action.PEDAL, toggled_on)
	_play_action_button_animation(Action.BOOST, toggled_on)


func _on_confirm_button_pressed() -> void:
	_resolve_turn(selected_action)


func _on_restart_button_pressed() -> void:
	_reset_state()
	game_end_container.hide()
