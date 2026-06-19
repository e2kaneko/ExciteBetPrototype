extends Area2D

# 進行方向(右)に向かって段差が高くなる、縞模様入りのドット絵ランプ。
const STEP_COUNT := 4
const STEP_WIDTH := 3
const STEP_HEIGHT := 2
const PIXEL_SIZE := 3.0
const COLOR_BASE := Color(1.0, 0.55, 0.0, 1.0)
const COLOR_SHADE := Color(0.75, 0.38, 0.0, 1.0)
const COLOR_HIGHLIGHT := Color(1.0, 0.75, 0.35, 1.0)

func _ready() -> void:
	_build_pixel_ramp()
	area_entered.connect(_on_area_entered)

func _build_pixel_ramp() -> void:
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
	if area.has_method("jump"):
		area.jump()
		queue_free()
