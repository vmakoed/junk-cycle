extends Node


const DISTANCE_LABEL_TEXT = "Distance: {current_distance}/{distance_goal}m"
const BATTERY_LABEL_TEXT = "{current_battery}%"
const TURNS_LABEL_TEXT = "{current_turn}/{total_turns}"


const DISTANCE_MIN = 0
const DISTANCE_GOAL = 1500
const BATTERY_MAX = 100
const BATTERY_MIN = 0
const BATTERY_DRAIN_PER_BOOST = 10
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


var current_distance : int : set = _set_current_distance  
var current_battery : int : set = _set_current_battery
var current_turn : int : set = _set_current_turn
var distance_per_pedal : int
var distance_per_boost : int
var pedal_enabled : bool : set = _set_pedal_enabled
var boost_enabled : bool : set = _set_boost_enabled


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
@onready var pedal_button : Button = %PedalButton
@onready var boost_button : Button = %BoostButton
@onready var turns_label : Label = %TurnsLabel
@onready var distance_progress_bar : ProgressBar = %DistanceProgressBar
@onready var current_turn_title : Label = %CurrentTurnTitle
@onready var current_turn_description : Label= %CurrentTurnDescription
@onready var next_turn_titles : Array[Label] = [%NextTurnTitle, %NextTurnTitle2, %NextTurnTitle3]


func _ready() -> void:
	_initialize_distance_progress_bar()
	current_distance = DISTANCE_MIN
	current_battery = BATTERY_MAX
	current_turn = TURNS_MIN


func _set_current_distance(new_value: int) -> void:
	current_distance = clamp(new_value, DISTANCE_MIN, DISTANCE_GOAL)

	_refresh_distance_label()
	_refresh_distance_progress_bar()

	if current_distance == DISTANCE_GOAL:
		_on_goal_reached()


func _set_current_battery(new_value: int) -> void:
	current_battery = clamp(new_value, BATTERY_MIN, BATTERY_MAX)

	if (current_battery < BATTERY_DRAIN_PER_BOOST):
		boost_enabled = false
	else:
		boost_enabled = true

	_refresh_battery_label()


func _set_current_turn(new_value: int) -> void:
	if new_value == turns.size():
		_on_out_of_turns()
	else:
		current_turn = clamp(new_value, TURNS_MIN, turns.size() - 1)
		_apply_turn_effects()
		
	_refresh_turn_label()
	_refresh_turn_info()
	_refresh_next_turns()


func _set_pedal_enabled(new_value: bool) -> void:
	pedal_enabled = new_value
	pedal_button.disabled = not pedal_enabled


func _set_boost_enabled(new_value: bool) -> void:
	boost_enabled = new_value
	boost_button.disabled = not boost_enabled


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


func _refresh_next_turns() -> void:
	for next_turn_difference in next_turn_titles.size():
		var next_turn := current_turn + 1 + next_turn_difference
		if next_turn >= turns.size():
			next_turn_titles[next_turn_difference].text = ""
		else:
			next_turn_titles[next_turn_difference].text = turn_titles[turns[next_turn]]


func _apply_turn_effects() -> void:
	distance_per_pedal = distances_per_pedal[turns[current_turn]]
	distance_per_boost = distances_per_boost[turns[current_turn]]


func _on_out_of_turns() -> void:
	if current_distance < DISTANCE_GOAL:
		print("you lose :(")

	_on_final_turn_played()


func _on_goal_reached() -> void:
	print("you win!")
	_on_final_turn_played()


func _on_final_turn_played() -> void:
	pedal_enabled = false
	boost_enabled = false
	
 
func _resolve_turn(movement: Action) -> void: 
	match movement:
		Action.PEDAL: 
			current_distance += distance_per_pedal
		Action.BOOST: 
			current_distance += distance_per_boost
			current_battery -= BATTERY_DRAIN_PER_BOOST

	current_turn += TURNS_PER_MOVEMENT


func _on_pedal_button_pressed() -> void:
	_resolve_turn(Action.PEDAL)


func _on_boost_button_pressed() -> void:
	_resolve_turn(Action.BOOST)
