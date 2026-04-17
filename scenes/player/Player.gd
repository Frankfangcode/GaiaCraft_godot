extends CharacterBody2D

const TILE_SIZE := 32
const MOVE_DURATION := 0.15
const WALK_FPS := 10.0
const IDLE_FPS := 6.0
const FRAMES_PER_DIR := 6

var is_moving := false
var facing := Vector2.DOWN

@onready var ray: RayCast2D = $RayCast2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Walk frame bases (user rows are 1-indexed, subtract 1 for 0-indexed)
var _walk_base := {
	Vector2.DOWN: 18,   # 0-indexed Row 3 (user's Row 4)
	Vector2.UP: 30,     # 0-indexed Row 5 (user's Row 6)
	Vector2.RIGHT: 24,  # 0-indexed Row 4 (user's Row 5)
	Vector2.LEFT: 24,   # same as RIGHT, mirrored via flip_h
}

# Idle frame base — Row 0 (user's Row 1) for down, first walk frame for others
var _idle_base := {
	Vector2.DOWN: 0,    # 0-indexed Row 0 (user's Row 1, dedicated idle)
	Vector2.UP: 30,     # first frame of walk up
	Vector2.RIGHT: 24,  # first frame of walk right
	Vector2.LEFT: 24,   # mirrored
}

var _dir_names := {
	Vector2.DOWN: "down",
	Vector2.UP: "up",
	Vector2.LEFT: "left",
	Vector2.RIGHT: "right",
}

func _ready() -> void:
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	_create_animations()
	sprite.frame = 0

func _create_animations() -> void:
	var lib := AnimationLibrary.new()

	for dir in _walk_base:
		var dir_name: String = _dir_names[dir]
		var walk_start: int = _walk_base[dir]
		var idle_start: int = _idle_base[dir]

		# Walk animation — 6 frames, looping
		var walk_anim := Animation.new()
		walk_anim.length = float(FRAMES_PER_DIR) / WALK_FPS
		walk_anim.loop_mode = Animation.LOOP_LINEAR
		var track := walk_anim.add_track(Animation.TYPE_VALUE)
		walk_anim.track_set_path(track, "Sprite2D:frame")
		walk_anim.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
		for i in range(FRAMES_PER_DIR):
			walk_anim.track_insert_key(track, i / WALK_FPS, walk_start + i)
		lib.add_animation("walk_" + dir_name, walk_anim)

		# Idle animation
		var idle_anim := Animation.new()
		idle_anim.loop_mode = Animation.LOOP_LINEAR
		var idle_track := idle_anim.add_track(Animation.TYPE_VALUE)
		idle_anim.track_set_path(idle_track, "Sprite2D:frame")
		idle_anim.value_track_set_update_mode(idle_track, Animation.UPDATE_DISCRETE)

		if dir == Vector2.DOWN:
			# Row 1 — full 6-frame idle cycle
			idle_anim.length = float(FRAMES_PER_DIR) / IDLE_FPS
			for i in range(FRAMES_PER_DIR):
				idle_anim.track_insert_key(idle_track, i / IDLE_FPS, idle_start + i)
		else:
			# Hold first frame of walk row
			idle_anim.length = 0.1
			idle_anim.track_insert_key(idle_track, 0.0, idle_start)

		lib.add_animation("idle_" + dir_name, idle_anim)

	anim_player.add_animation_library("", lib)

func _physics_process(_delta: float) -> void:
	if is_moving:
		return

	if DialogueManager.is_active:
		_play_idle()
		return

	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_dir = Vector2.UP
	elif Input.is_action_pressed("ui_down"):
		input_dir = Vector2.DOWN
	elif Input.is_action_pressed("ui_left"):
		input_dir = Vector2.LEFT
	elif Input.is_action_pressed("ui_right"):
		input_dir = Vector2.RIGHT

	if input_dir == Vector2.ZERO:
		_play_idle()
		return

	facing = input_dir

	# Check for obstacle
	ray.target_position = input_dir * TILE_SIZE
	ray.force_raycast_update()

	if ray.is_colliding():
		_play_idle()
		return

	# Move one tile
	_play_walk()
	is_moving = true
	var target_pos := position + input_dir * TILE_SIZE
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, MOVE_DURATION)
	tween.tween_callback(_on_move_finished)

func _play_walk() -> void:
	sprite.flip_h = (facing == Vector2.LEFT)
	var anim_name: String = "walk_" + _dir_names[facing]
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _play_idle() -> void:
	sprite.flip_h = (facing == Vector2.LEFT)
	var anim_name: String = "idle_" + _dir_names[facing]
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _on_move_finished() -> void:
	is_moving = false
