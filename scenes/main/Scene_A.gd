extends Node2D

func _ready() -> void:
	var map: Sprite2D = $MapBackground
	var camera: Camera2D = $Player/Camera2D
	var tex_size := map.texture.get_size()

	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(tex_size.x)
	camera.limit_bottom = int(tex_size.y)
