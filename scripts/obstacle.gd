extends Area2D

# ドット絵の泥のぬかるみ。D=深い泥影 M=泥(#5c2c16) H=テカリ(ハイライト) .=透明
const PIXEL_SIZE := 2.5
const SPRITE_ROWS := [
	"...DMMMMD...",
	"..DMMHHMMD..",
	".DMMHHHHMMD.",
	".DMMHHHHMMD.",
	"..DMMHHMMD..",
	"...DMMMMD...",
]
const PIXEL_PALETTE := {
	"D": Color(0.231373, 0.109804, 0.054902, 1.0),
	"M": Color(0.360784, 0.172549, 0.086275, 1.0),
	"H": Color(0.545098, 0.290196, 0.168627, 1.0),
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
	if area.has_method("apply_mud"):
		area.apply_mud()
		queue_free()
