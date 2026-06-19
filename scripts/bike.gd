extends Area2D
class_name Bike

enum BikeColor { RED, BLUE, YELLOW }

const COLOR_NAMES := {
	BikeColor.RED: "赤",
	BikeColor.BLUE: "青",
	BikeColor.YELLOW: "黄",
}
const COLOR_VALUES := {
	BikeColor.RED: Color.RED,
	BikeColor.BLUE: Color.BLUE,
	BikeColor.YELLOW: Color.YELLOW,
}

const MUD_DISTANCE := 5.0
const MUD_MULTIPLIER := 0.5
const BOOST_DISTANCE := 30.0
const BOOST_MULTIPLIER := 2.0

@export var bike_color: BikeColor = BikeColor.RED
@export var base_speed: float = 60.0

var effect_multiplier: float = 1.0
var effect_distance_remaining: float = 0.0
var finished: bool = false

signal finished_race(bike)

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.color = COLOR_VALUES[bike_color]

func _physics_process(delta: float) -> void:
	if finished:
		return

	var move_amount: float = base_speed * effect_multiplier * delta
	position.x += move_amount

	if effect_distance_remaining > 0.0:
		effect_distance_remaining -= move_amount
		if effect_distance_remaining <= 0.0:
			effect_distance_remaining = 0.0
			effect_multiplier = 1.0

func apply_mud() -> void:
	effect_multiplier = MUD_MULTIPLIER
	effect_distance_remaining = MUD_DISTANCE

func apply_boost() -> void:
	effect_multiplier = BOOST_MULTIPLIER
	effect_distance_remaining = BOOST_DISTANCE

func get_color_name() -> String:
	return COLOR_NAMES.get(bike_color, "")
