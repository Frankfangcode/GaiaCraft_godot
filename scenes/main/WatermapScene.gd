extends Node2D

func _ready() -> void:
	var map: Sprite2D = $MapBackground
	var camera: Camera2D = $Player/Camera2D
	var world_size := map.texture.get_size() * map.scale

	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_size.x)
	camera.limit_bottom = int(world_size.y)
