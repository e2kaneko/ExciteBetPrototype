extends Area2D

# 進行方向(右)に向かって段差が高くなる、土の斜面を思わせるドット絵の階層構造。
const STEP_COUNT := 5
const STEP_WIDTH := 5
const STEP_HEIGHT := 2
const PIXEL_SIZE := 2.4
const COLOR_BASE := Color(0.541176, 0.427451, 0.231373, 1.0)
const COLOR_SHADE := Color(0.419608, 0.317647, 0.156863, 1.0)
const COLOR_HIGHLIGHT := Color(0.721569, 0.627451, 0.415686, 1.0)

func _ready() -> void:
	_build_pixel_slope()
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _build_pixel_slope() -> void:
	var grid_width: int = STEP_COUNT * STEP_WIDTH
	var grid_height: int = STEP_COUNT * STEP_HEIGHT
	var origin := Vector2(-grid_width * PIXEL_SIZE / 2.0, -grid_height * PIXEL_SIZE / 2.0)

	for col in grid_width:
		var step_index: int = col / STEP_WIDTH
		var column_height: int = (step_index + 1) * STEP_HEIGHT
		var top_row: int = grid_height - column_height
		for row in range(top_row, grid_height):
			var pixel_color: Color
			if row == top_row:
				pixel_color = COLOR_HIGHLIGHT
			elif row % 2 == 0:
				pixel_color = COLOR_BASE
			else:
				pixel_color = COLOR_SHADE
			var pixel := Polygon2D.new()
			pixel.position = origin + Vector2(col * PIXEL_SIZE, row * PIXEL_SIZE)
			pixel.polygon = PackedVector2Array([
				Vector2(0.0, 0.0),
				Vector2(PIXEL_SIZE, 0.0),
				Vector2(PIXEL_SIZE, PIXEL_SIZE),
				Vector2(0.0, PIXEL_SIZE),
			])
			pixel.vertex_colors = PackedColorArray([pixel_color, pixel_color, pixel_color, pixel_color])
			add_child(pixel)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("enter_slope"):
		area.enter_slope()

func _on_area_exited(area: Area2D) -> void:
	if area.has_method("exit_slope"):
		area.exit_slope()
