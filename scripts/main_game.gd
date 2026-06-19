extends Node2D

const BIKE_SCENE := preload("res://scenes/bike.tscn")
const OBSTACLE_SCENE := preload("res://scenes/obstacle.tscn")
const BOOST_SCENE := preload("res://scenes/boost_item.tscn")
const JUMP_PAD_SCENE := preload("res://scenes/jump_pad.tscn")
const SLOPE_SCENE := preload("res://scenes/slope.tscn")

const LANE_SPACING := 100.0
const LANE_START_Y := 100.0
const SPAWN_MARGIN := 40.0

const START_MARGIN_RATIO := 0.05
const START_MARGIN_MIN := 50.0
const GOAL_MARGIN_RATIO := 0.05
const GOAL_MARGIN_MIN := 100.0

const DIRT_TRACK_TOP := 60.0
const DIRT_TRACK_BOTTOM := 340.0
const START_LINE_OFFSET := 35.0
const GOAL_LABEL_OFFSET := 20.0
const GOAL_LABEL_WIDTH := 40.0
const GOAL_LABEL_FONT_SIZE := 28

# 元のデザイン（横幅450pxの画面でトラック長400px・速度60px/sを想定）との
# 速度バランスを保つための基準値。画面幅が変わっても所要時間が大きく変わらないよう
# トラック長に比例してbase_speedを再計算する。
const REFERENCE_TRACK_LENGTH := 400.0
const REFERENCE_BASE_SPEED := 60.0

const OBSTACLES_PER_LANE := 4
const BOOSTS_PER_LANE := 3
const JUMP_PADS_PER_LANE := 2
const SLOPES_PER_LANE := 2

enum GameState { START_WAIT, RACING, FINISHED }

@onready var result_label: Label = $UILayer/ResultLabel
@onready var start_label: Label = $UILayer/StartLabel
@onready var reset_label: Label = $UILayer/ResetLabel
@onready var grass_background: ColorRect = $GrassBackground
@onready var dirt_track: ColorRect = $DirtTrack

var bikes: Array[Bike] = []
var track_items: Array[Node] = []
var state: GameState = GameState.START_WAIT
var start_x: float = 0.0
var goal_x: float = 0.0
var track_length: float = 0.0

func _ready() -> void:
	randomize()
	result_label.text = ""
	_calculate_track_bounds()
	_spawn_track_lines()
	_spawn_bikes()
	_spawn_track_items()

func _unhandled_input(event: InputEvent) -> void:
	var is_space_press: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE
	var is_left_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	match state:
		GameState.START_WAIT:
			if is_space_press or is_left_click:
				_start_race()
		GameState.FINISHED:
			if is_left_click:
				_reset_game()

func _start_race() -> void:
	state = GameState.RACING
	start_label.visible = false
	for bike in bikes:
		bike.start_race()

func _reset_game() -> void:
	result_label.text = ""
	reset_label.visible = false

	for item in track_items:
		if is_instance_valid(item):
			item.queue_free()
	track_items.clear()
	_spawn_track_items()

	for i in bikes.size():
		var lane_y: float = LANE_START_Y + i * LANE_SPACING
		bikes[i].reset(Vector2(start_x, lane_y))

	start_label.visible = true
	state = GameState.START_WAIT

func _calculate_track_bounds() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_width: float = viewport_size.x
	start_x = max(screen_width * START_MARGIN_RATIO, START_MARGIN_MIN)
	goal_x = screen_width - max(screen_width * GOAL_MARGIN_RATIO, GOAL_MARGIN_MIN)
	if goal_x <= start_x:
		goal_x = start_x + 1.0
	track_length = goal_x - start_x
	_setup_background(viewport_size)

func _setup_background(viewport_size: Vector2) -> void:
	grass_background.position = Vector2.ZERO
	grass_background.size = viewport_size
	dirt_track.position = Vector2(0.0, DIRT_TRACK_TOP)
	dirt_track.size = Vector2(viewport_size.x, DIRT_TRACK_BOTTOM - DIRT_TRACK_TOP)

func _spawn_track_lines() -> void:
	var num_lanes := 3
	var lines_height: float = LANE_SPACING * (num_lanes - 1) + 60.0

	var start_line := ColorRect.new()
	start_line.color = Color.WHITE
	start_line.size = Vector2(5, lines_height)
	start_line.position = Vector2(start_x + START_LINE_OFFSET, LANE_START_Y - 30)
	add_child(start_line)

	for i in range(1, num_lanes):
		var divider := ColorRect.new()
		divider.color = Color.WHITE
		divider.size = Vector2(goal_x - start_x, 2)
		divider.position = Vector2(start_x, LANE_START_Y + LANE_SPACING * i - LANE_SPACING / 2.0 - 1.0)
		add_child(divider)

func _spawn_bikes() -> void:
	var colors := [Bike.BikeColor.RED, Bike.BikeColor.BLUE, Bike.BikeColor.YELLOW]
	var balanced_speed: float = REFERENCE_BASE_SPEED * (track_length / REFERENCE_TRACK_LENGTH)
	for i in colors.size():
		var lane_y: float = LANE_START_Y + i * LANE_SPACING
		var bike: Bike = _create_bike(colors[i], balanced_speed, lane_y)
		bikes.append(bike)

	var goal_line := ColorRect.new()
	goal_line.color = Color.WHITE
	goal_line.size = Vector2(5, LANE_SPACING * (colors.size() - 1) + 60)
	goal_line.position = Vector2(goal_x, LANE_START_Y - 30)
	add_child(goal_line)

	_spawn_goal_label()

func _spawn_goal_label() -> void:
	var goal_label := Label.new()
	goal_label.text = "G\nO\nA\nL"
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	goal_label.add_theme_font_size_override("font_size", GOAL_LABEL_FONT_SIZE)
	goal_label.add_theme_color_override("font_color", Color.WHITE)
	goal_label.add_theme_color_override("font_outline_color", Color.BLACK)
	goal_label.add_theme_constant_override("outline_size", 4)

	# レトロなギザギザ文字に見えるよう、アンチエイリアスとヒンティングを切った
	# フォントを複製して適用する（画像フォント等の追加アセットは使わない）。
	var base_font: Font = ThemeDB.fallback_font
	if base_font is FontFile:
		var retro_font: FontFile = (base_font as FontFile).duplicate()
		retro_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		retro_font.hinting = TextServer.HINTING_NONE
		retro_font.oversampling = 1.0
		goal_label.add_theme_font_override("font", retro_font)

	goal_label.size = Vector2(GOAL_LABEL_WIDTH, DIRT_TRACK_BOTTOM - DIRT_TRACK_TOP)
	goal_label.position = Vector2(goal_x + GOAL_LABEL_OFFSET, DIRT_TRACK_TOP)
	add_child(goal_label)

func _create_bike(color: Bike.BikeColor, speed: float, lane_y: float) -> Bike:
	var bike: Bike = BIKE_SCENE.instantiate()
	bike.bike_color = color
	bike.base_speed = speed
	bike.position = Vector2(start_x, lane_y)
	bike.finished_race.connect(_on_bike_finished)
	add_child(bike)
	return bike

func _spawn_track_items() -> void:
	var spawn_min: float = start_x + SPAWN_MARGIN
	var spawn_max: float = goal_x - SPAWN_MARGIN
	if spawn_min >= spawn_max:
		spawn_min = start_x
		spawn_max = goal_x

	for i in bikes.size():
		var lane_y: float = LANE_START_Y + i * LANE_SPACING
		for j in OBSTACLES_PER_LANE:
			var obstacle := OBSTACLE_SCENE.instantiate()
			obstacle.position = Vector2(randf_range(spawn_min, spawn_max), lane_y)
			add_child(obstacle)
			track_items.append(obstacle)
		for j in BOOSTS_PER_LANE:
			var boost := BOOST_SCENE.instantiate()
			boost.position = Vector2(randf_range(spawn_min, spawn_max), lane_y)
			add_child(boost)
			track_items.append(boost)
		for j in JUMP_PADS_PER_LANE:
			var jump_pad := JUMP_PAD_SCENE.instantiate()
			jump_pad.position = Vector2(randf_range(spawn_min, spawn_max), lane_y)
			add_child(jump_pad)
			track_items.append(jump_pad)
		for j in SLOPES_PER_LANE:
			var slope := SLOPE_SCENE.instantiate()
			slope.position = Vector2(randf_range(spawn_min, spawn_max), lane_y)
			add_child(slope)
			track_items.append(slope)

func _physics_process(_delta: float) -> void:
	if state != GameState.RACING:
		return
	for bike in bikes:
		if not bike.finished and bike.position.x >= goal_x:
			bike.finished = true
			bike.finished_race.emit(bike)

func _on_bike_finished(bike: Bike) -> void:
	if state != GameState.RACING:
		return
	state = GameState.FINISHED
	result_label.text = "1着：%sのバイク！" % bike.get_color_name()
	reset_label.visible = true
