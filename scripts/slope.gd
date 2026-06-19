extends Area2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("enter_slope"):
		area.enter_slope()

func _on_area_exited(area: Area2D) -> void:
	if area.has_method("exit_slope"):
		area.exit_slope()
