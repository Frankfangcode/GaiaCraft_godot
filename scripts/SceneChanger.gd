extends Node

var is_transitioning := false

var _canvas_layer: CanvasLayer
var _color_rect: ColorRect
var _video_player: VideoStreamPlayer
var _player_spawn_pos: Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 20
	add_child(_canvas_layer)

	_color_rect = ColorRect.new()
	_color_rect.color = Color.BLACK
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.modulate.a = 0.0
	_canvas_layer.add_child(_color_rect)

	_video_player = VideoStreamPlayer.new()
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video_player.visible = false
	_canvas_layer.add_child(_video_player)

## 一般換場（黑色淡入淡出）
func change_scene(path: String, player_spawn_pos: Vector2) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_player_spawn_pos = player_spawn_pos

	var tween := create_tween()
	tween.tween_property(_color_rect, "modulate:a", 1.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	var player := get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.global_position = _player_spawn_pos

	var fade_out := create_tween()
	fade_out.tween_property(_color_rect, "modulate:a", 0.0, 0.3)
	await fade_out.finished

	is_transitioning = false

## 影片過場換場（播完影片再切換場景）
func change_scene_with_video(
		video_path: String,
		scene_path: String,
		player_spawn_pos: Vector2
) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_player_spawn_pos = player_spawn_pos

	# 載入並播放影片
	var stream := load(video_path)
	if stream == null:
		push_error("SceneChanger: 找不到影片 " + video_path)
		is_transitioning = false
		return

	_video_player.stream = stream
	_video_player.visible = true
	_video_player.play()

	# 等影片播完
	await _video_player.finished

	_video_player.visible = false
	_video_player.stream = null

	# 黑畫面切換
	_color_rect.modulate.a = 1.0
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	var player := get_tree().current_scene.find_child("Player", true, false)
	if player:
		player.global_position = _player_spawn_pos

	var fade_out := create_tween()
	fade_out.tween_property(_color_rect, "modulate:a", 0.0, 0.4)
	await fade_out.finished

	is_transitioning = false
