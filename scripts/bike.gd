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
const SLOPE_MULTIPLIER := 0.7
const AIRBORNE_MULTIPLIER := 1.3
# 前輪(右側)が進行方向なので、負の回転角でノーズアップにする
const JUMP_TILT := -0.25

# レトロなドット絵バイク（横向き・右側が前輪）を表すピクセルグリッド。
# K=タイヤ(黒) G=フレーム/エンジン(グレー) R=ライダー(白) C=カウル(チームカラー) .=透明
const PIXEL_SIZE := 3.0
const SPRITE_ROWS := [
	"......RR........",
	".....RRRR..G....",
	"....CCCCCCC.....",
	"...GCCCCCCCCG...",
	".KK....GG...KK..",
	"KKKK....GG..KKKK",
	"KKKK........KKKK",
	".KK..........KK.",
	"................",
]
const PIXEL_PALETTE := {
	"K": Color(0.05, 0.05, 0.05, 1.0),
	"G": Color(0.55, 0.55, 0.55, 1.0),
	"R": Color(0.92, 0.92, 0.92, 1.0),
}

@export var bike_color: BikeColor = BikeColor.RED
@export var base_speed: float = 60.0
@export var fall_gravity: float = 600.0
@export var jump_force: float = 220.0

var effect_multiplier: float = 1.0
var effect_distance_remaining: float = 0.0
var slope_multiplier: float = 1.0
var ground_y: float = 0.0
var velocity_y: float = 0.0
var finished: bool = false
var race_started: bool = false

signal finished_race(bike)

func _ready() -> void:
	_build_pixel_sprite()
	ground_y = position.y

func _build_pixel_sprite() -> void:
	var palette: Dictionary = PIXEL_PALETTE.duplicate()
	palette["C"] = COLOR_VALUES[bike_color]

	var grid_width: int = SPRITE_ROWS[0].length()
	var grid_height: int = SPRITE_ROWS.size()
	var origin := Vector2(-grid_width * PIXEL_SIZE / 2.0, -grid_height * PIXEL_SIZE / 2.0)

	for row in grid_height:
		var line: String = SPRITE_ROWS[row]
		for col in grid_width:
			var key: String = line[col]
			if key == ".":
				continue
			var pixel := Polygon2D.new()
			pixel.position = origin + Vector2(col * PIXEL_SIZE, row * PIXEL_SIZE)
			pixel.polygon = PackedVector2Array([
				Vector2(0.0, 0.0),
				Vector2(PIXEL_SIZE, 0.0),
				Vector2(PIXEL_SIZE, PIXEL_SIZE),
				Vector2(0.0, PIXEL_SIZE),
			])
			var pixel_color: Color = palette[key]
			pixel.vertex_colors = PackedColorArray([pixel_color, pixel_color, pixel_color, pixel_color])
			add_child(pixel)

func _physics_process(delta: float) -> void:
	if finished or not race_started:
		return

	var is_airborne: bool = position.y < ground_y
	rotation = JUMP_TILT if is_airborne else 0.0
	var air_multiplier: float = AIRBORNE_MULTIPLIER if is_airborne else 1.0
	var move_amount: float = base_speed * effect_multiplier * slope_multiplier * air_multiplier * delta
	position.x += move_amount

	velocity_y += fall_gravity * delta
	position.y += velocity_y * delta
	if position.y >= ground_y:
		position.y = ground_y
		velocity_y = 0.0

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

func jump() -> void:
	if position.y >= ground_y - 0.01:
		velocity_y = -jump_force

func enter_slope() -> void:
	slope_multiplier = SLOPE_MULTIPLIER

func exit_slope() -> void:
	slope_multiplier = 1.0

func start_race() -> void:
	race_started = true

func get_color_name() -> String:
	return COLOR_NAMES.get(bike_color, "")
