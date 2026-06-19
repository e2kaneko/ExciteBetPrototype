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

# ジャンプの離陸・着地エフェクト
const SQUASH_STRETCH_DURATION := 0.15
const TAKEOFF_SCALE := Vector2(0.7, 1.3)
const LANDING_SCALE := Vector2(1.3, 0.7)
const DUST_PARTICLE_COUNT := 6
const DUST_BURST_DURATION := 0.3
const DUST_COLOR := Color(0.9, 0.85, 0.7, 0.9)

# 泥はね（接触時に一度だけ）
const MUD_SPLASH_PARTICLE_COUNT := 6
const MUD_SPLASH_DURATION := 0.35
const MUD_SPLASH_COLOR := Color(0.360784, 0.172549, 0.086275, 1.0)

# ブースト中のマフラーの火炎（継続的に生成）
const BOOST_FLAME_INTERVAL := 0.05
const BOOST_FLAME_LIFETIME := 0.25
const BOOST_FLAME_COLORS := [
	Color(1.0, 0.9, 0.2, 1.0),
	Color(1.0, 0.5, 0.0, 1.0),
	Color(1.0, 0.2, 0.0, 1.0),
]

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
var sprite_half_height: float = 0.0
var sprite_half_width: float = 0.0
var boost_flame_timer: float = 0.0

signal finished_race(bike)

func _ready() -> void:
	_build_pixel_sprite()
	ground_y = position.y

func _build_pixel_sprite() -> void:
	var palette: Dictionary = PIXEL_PALETTE.duplicate()
	palette["C"] = COLOR_VALUES[bike_color]

	var grid_width: int = SPRITE_ROWS[0].length()
	var grid_height: int = SPRITE_ROWS.size()
	sprite_half_height = grid_height * PIXEL_SIZE / 2.0
	sprite_half_width = grid_width * PIXEL_SIZE / 2.0
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

	var was_airborne: bool = position.y < ground_y
	rotation = JUMP_TILT if was_airborne else 0.0
	var air_multiplier: float = AIRBORNE_MULTIPLIER if was_airborne else 1.0
	var move_amount: float = base_speed * effect_multiplier * slope_multiplier * air_multiplier * delta
	position.x += move_amount

	velocity_y += fall_gravity * delta
	position.y += velocity_y * delta
	if position.y >= ground_y:
		position.y = ground_y
		velocity_y = 0.0
		if was_airborne:
			_play_landing_effect()

	var is_boosting: bool = effect_multiplier == BOOST_MULTIPLIER and effect_distance_remaining > 0.0
	if is_boosting:
		boost_flame_timer -= delta
		if boost_flame_timer <= 0.0:
			boost_flame_timer = BOOST_FLAME_INTERVAL
			_spawn_boost_flame()
	else:
		boost_flame_timer = 0.0

	if effect_distance_remaining > 0.0:
		effect_distance_remaining -= move_amount
		if effect_distance_remaining <= 0.0:
			effect_distance_remaining = 0.0
			effect_multiplier = 1.0

func apply_mud() -> void:
	effect_multiplier = MUD_MULTIPLIER
	effect_distance_remaining = MUD_DISTANCE
	_spawn_particle_burst(MUD_SPLASH_COLOR, MUD_SPLASH_PARTICLE_COUNT, MUD_SPLASH_DURATION, Vector2(-PI, 0.0), Vector2(6.0, 14.0))

func apply_boost() -> void:
	effect_multiplier = BOOST_MULTIPLIER
	effect_distance_remaining = BOOST_DISTANCE

func jump() -> void:
	if position.y >= ground_y - 0.01:
		velocity_y = -jump_force
		_play_takeoff_effect()

func _play_takeoff_effect() -> void:
	scale = TAKEOFF_SCALE
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, SQUASH_STRETCH_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spawn_particle_burst(DUST_COLOR, DUST_PARTICLE_COUNT, DUST_BURST_DURATION, Vector2(-PI * 0.8, -PI * 0.2), Vector2(8.0, 18.0))

func _play_landing_effect() -> void:
	scale = LANDING_SCALE
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, SQUASH_STRETCH_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_spawn_particle_burst(DUST_COLOR, DUST_PARTICLE_COUNT, DUST_BURST_DURATION, Vector2(-PI * 0.8, -PI * 0.2), Vector2(8.0, 18.0))

# 地面に残るパーティクル（土煙・泥はね）。ワールド座標系の親に追加し、
# バイク本体の移動・回転・拡縮に影響されないようにする。
func _spawn_particle_burst(burst_color: Color, count: int, duration: float, angle_range: Vector2, distance_range: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var burst_origin: Vector2 = global_position + Vector2(0.0, sprite_half_height)

	for i in count:
		var particle := Polygon2D.new()
		var size: float = randf_range(2.0, 4.0)
		particle.polygon = PackedVector2Array([
			Vector2(-size / 2.0, -size / 2.0),
			Vector2(size / 2.0, -size / 2.0),
			Vector2(size / 2.0, size / 2.0),
			Vector2(-size / 2.0, size / 2.0),
		])
		particle.vertex_colors = PackedColorArray([burst_color, burst_color, burst_color, burst_color])
		particle.global_position = burst_origin
		parent_node.add_child(particle)

		var angle: float = randf_range(angle_range.x, angle_range.y)
		var distance: float = randf_range(distance_range.x, distance_range.y)
		var target_offset: Vector2 = Vector2(cos(angle), sin(angle)) * distance

		var particle_tween := particle.create_tween()
		particle_tween.set_parallel(true)
		particle_tween.tween_property(particle, "global_position", burst_origin + target_offset, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		particle_tween.tween_property(particle, "scale", Vector2.ZERO, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		particle_tween.tween_property(particle, "modulate:a", 0.0, duration)
		particle_tween.finished.connect(particle.queue_free)

# マフラーの火炎。バイク本体の子として追加し、車体の動き・傾きに追従させる。
func _spawn_boost_flame() -> void:
	var flame := Polygon2D.new()
	var size: float = randf_range(3.0, 5.0)
	flame.polygon = PackedVector2Array([
		Vector2(0.0, -size / 2.0),
		Vector2(size / 2.0, size / 2.0),
		Vector2(-size / 2.0, size / 2.0),
	])
	var flame_color: Color = BOOST_FLAME_COLORS[randi() % BOOST_FLAME_COLORS.size()]
	flame.vertex_colors = PackedColorArray([flame_color, flame_color, flame_color])

	var rear_point := Vector2(-sprite_half_width * 0.7, sprite_half_height * 0.3)
	flame.position = rear_point
	add_child(flame)

	var flame_offset := Vector2(randf_range(-10.0, -6.0), randf_range(-2.0, 2.0))
	var flame_tween := flame.create_tween()
	flame_tween.set_parallel(true)
	flame_tween.tween_property(flame, "position", rear_point + flame_offset, BOOST_FLAME_LIFETIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flame_tween.tween_property(flame, "scale", Vector2(0.2, 0.2), BOOST_FLAME_LIFETIME)
	flame_tween.tween_property(flame, "modulate:a", 0.0, BOOST_FLAME_LIFETIME)
	flame_tween.finished.connect(flame.queue_free)

func enter_slope() -> void:
	slope_multiplier = SLOPE_MULTIPLIER

func exit_slope() -> void:
	slope_multiplier = 1.0

func start_race() -> void:
	race_started = true

func reset(spawn_position: Vector2) -> void:
	position = spawn_position
	ground_y = spawn_position.y
	rotation = 0.0
	scale = Vector2.ONE
	velocity_y = 0.0
	effect_multiplier = 1.0
	effect_distance_remaining = 0.0
	slope_multiplier = 1.0
	boost_flame_timer = 0.0
	finished = false
	race_started = false

func get_color_name() -> String:
	return COLOR_NAMES.get(bike_color, "")
