extends Node2D

const BIKE_SCENE := preload("res://scenes/bike.tscn")
const OBSTACLE_SCENE := preload("res://scenes/obstacle.tscn")
const BOOST_SCENE := preload("res://scenes/boost_item.tscn")

const TRACK_LENGTH := 400.0
const START_X := 50.0
const LANE_SPACING := 100.0
const LANE_START_Y := 100.0
const SPAWN_MARGIN := 40.0

const OBSTACLES_PER_LANE := 4
const BOOSTS_PER_LANE := 3

@onready var result_label: Label = $ResultLabel

var bikes: Array[Bike] = []
var race_finished: bool = false

func _ready() -> void:
	randomize()
	result_label.text = ""
	_spawn_bikes()
	_spawn_track_items()

func _spawn_bikes() -> void:
	var colors := [Bike.BikeColor.RED, Bike.BikeColor.BLUE, Bike.BikeColor.YELLOW]
	for i in colors.size():
		var bike: Bike = BIKE_SCENE.instantiate()
		bike.bike_color = colors[i]
		bike.position = Vector2(START_X, LANE_START_Y + i * LANE_SPACING)
		bike.finished_race.connect(_on_bike_finished)
		add_child(bike)
		bikes.append(bike)

	var goal_line := ColorRect.new()
	goal_line.color = Color.WHITE
	goal_line.size = Vector2(5, LANE_SPACING * (colors.size() - 1) + 60)
	goal_line.position = Vector2(START_X + TRACK_LENGTH, LANE_START_Y - 30)
	add_child(goal_line)

func _spawn_track_items() -> void:
	for i in bikes.size():
		var lane_y: float = LANE_START_Y + i * LANE_SPACING
		for j in OBSTACLES_PER_LANE:
			var obstacle := OBSTACLE_SCENE.instantiate()
			obstacle.position = Vector2(
				randf_range(START_X + SPAWN_MARGIN, START_X + TRACK_LENGTH - SPAWN_MARGIN),
				lane_y
			)
			add_child(obstacle)
		for j in BOOSTS_PER_LANE:
			var boost := BOOST_SCENE.instantiate()
			boost.position = Vector2(
				randf_range(START_X + SPAWN_MARGIN, START_X + TRACK_LENGTH - SPAWN_MARGIN),
				lane_y
			)
			add_child(boost)

func _physics_process(_delta: float) -> void:
	if race_finished:
		return
	for bike in bikes:
		if not bike.finished and bike.position.x >= START_X + TRACK_LENGTH:
			bike.finished = true
			bike.finished_race.emit(bike)

func _on_bike_finished(bike: Bike) -> void:
	if race_finished:
		return
	race_finished = true
	result_label.text = "1着：%sのバイク！" % bike.get_color_name()
