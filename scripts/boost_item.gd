extends Area2D

# ドット絵のイナズマ。Y=鮮やかな黄色(#FFFF00) O=陰の縁取り(琥珀) .=透明
const PIXEL_SIZE := 2.5
const SPRITE_ROWS := [
	"....YO..",
	"...YYO..",
	"..YYO...",
	".YYO....",
	"YYYYYYO.",
	".YYYYYO.",
	"..YYO...",
	"...YYO..",
	"....YYO.",
	".....YO.",
	"....YO..",
	"...YO...",
]
const PIXEL_PALETTE := {
	"Y": Color(1.0, 1.0, 0.0, 1.0),
	"O": Color(0.8, 0.6, 0.0, 1.0),
}

func _ready() -> void:
	_build_pixel_sprite()
	area_entered.connect(_on_area_entered)

func _build_pixel_sprite() -> void:
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
			var pixel_color: Color = PIXEL_PALETTE[key]
			pixel.vertex_colors = PackedColorArray([pixel_color, pixel_color, pixel_color, pixel_color])
			add_child(pixel)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("apply_boost"):
		area.apply_boost()
		queue_free()
