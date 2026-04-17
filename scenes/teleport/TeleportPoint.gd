extends Area2D

@export_file("*.tscn") var target_scene_path: String = ""
@export var spawn_location: Vector2 = Vector2.ZERO

var _visual: ColorRect

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_create_visual()

func _create_visual() -> void:
	_visual = ColorRect.new()
	_visual.color = Color(0.2, 0.6, 1.0, 0.6)
	_visual.size = Vector2(32, 64)
	_visual.position = Vector2(-16, -32)
	add_child(_visual)

	# Pulsing animation
	var tween := create_tween().set_loops()
	tween.tween_property(_visual, "color:a", 0.2, 0.8)
	tween.tween_property(_visual, "color:a", 0.6, 0.8)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and target_scene_path != "":
		SceneChanger.change_scene(target_scene_path, spawn_location)
