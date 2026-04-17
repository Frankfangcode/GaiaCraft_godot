extends Node2D

func _ready() -> void:
	var map: Sprite2D = $MapBackground
	var camera: Camera2D = $Player/Camera2D
	var tex_size := map.texture.get_size() * map.scale
	var map_pos := map.position

	camera.limit_left = int(map_pos.x)
	camera.limit_top = int(map_pos.y)
	camera.limit_right = int(map_pos.x + tex_size.x)
	camera.limit_bottom = int(map_pos.y + tex_size.y)
