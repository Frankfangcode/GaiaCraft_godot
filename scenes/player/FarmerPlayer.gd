extends CharacterBody2D
## ============================================================
## 農夫玩家 — 多圖層換裝 + 動畫同步 + 工具切換
## ============================================================

const TILE_SIZE := 32
const MOVE_DURATION := 0.15

# ─── 精靈圖規格 ───
const CHAR_HFRAMES := 56
const CHAR_VFRAMES := 22
const TOOL_HFRAMES := 120
const TOOL_VFRAMES := 9

# ─── 方向 ───
enum Dir { DOWN = 0, RIGHT = 1, UP = 2, LEFT = 3 }
const DIR_VEC := {
	Dir.DOWN: Vector2.DOWN,
	Dir.RIGHT: Vector2.RIGHT,
	Dir.UP: Vector2.UP,
	Dir.LEFT: Vector2.LEFT,
}

# ─── 動畫定義 ───
# char_row: 角色精靈圖列號
# tool_row: 工具精靈圖列號 (-1 = 無工具)
# fpd: 每方向幀數  fps: 播放速率  loop: 循環  needs_tool: 顯示工具層
# ※ fpd 數值依據 32x32 Body_1.png 目視計算，如有誤差可微調
const ANIMS := {
	"idle":           {char_row=1,  tool_row=0,  fpd=9,  fps=8.0,  loop=true,  needs_tool=true},
	"walk":           {char_row=2,  tool_row=1,  fpd=6,  fps=8.0,  loop=true,  needs_tool=true},
	"harvest":        {char_row=3,  tool_row=-1, fpd=6,  fps=8.0,  loop=false, needs_tool=false},
	"dig":            {char_row=4,  tool_row=2,  fpd=9,  fps=10.0, loop=false, needs_tool=true},
	"watering":       {char_row=6,  tool_row=3,  fpd=14, fps=10.0, loop=false, needs_tool=true},
	"chopping":       {char_row=7,  tool_row=4,  fpd=10, fps=10.0, loop=false, needs_tool=true},
	"fishing_throw":  {char_row=8,  tool_row=5,  fpd=9,  fps=10.0, loop=false, needs_tool=true},
	"fishing_idle":   {char_row=9,  tool_row=6,  fpd=8,  fps=6.0,  loop=true,  needs_tool=true},
	"fishing_pull":   {char_row=10, tool_row=7,  fpd=6,  fps=10.0, loop=false, needs_tool=true},
	"fishing_caught": {char_row=12, tool_row=8,  fpd=14, fps=10.0, loop=false, needs_tool=true},
}

# 工具 → 動作對應
const TOOL_ACTION := {
	"Axe": "chopping",
	"Shovel": "dig",
	"Watering_Can": "watering",
	"Fishing_Rod": "fishing_throw",
}

# ─── 節點參考 ───
var _char_sprites: Array[Sprite2D] = []
var _tool_sprite: Sprite2D
var _anim_player: AnimationPlayer
var _ray: RayCast2D
var _camera: Camera2D

# ─── 狀態 ───
var _direction: int = Dir.DOWN
var _is_moving := false
var _is_acting := false   # 正在執行工具動作
var _current_anim := "idle"

# ─── 幀同步屬性（由 AnimationPlayer 驅動）───
var char_frame: int = 0:
	set(value):
		char_frame = value
		for s in _char_sprites:
			s.frame = value

var tool_frame: int = 0:
	set(value):
		tool_frame = value
		if _tool_sprite:
			_tool_sprite.frame = value


func _ready() -> void:
	_create_nodes()
	_build_all_animations()

	# 連接 CharacterManager 信號
	if Engine.get_singleton("CharacterManager") or has_node("/root/CharacterManager"):
		CharacterManager.appearance_changed.connect(_refresh_textures)
		CharacterManager.tool_changed.connect(_on_tool_changed)
		_refresh_textures()

	_play("idle")


# ════════════════════════════════════════════════════════════
#  節點建立
# ════════════════════════════════════════════════════════════

func _create_nodes() -> void:
	# 碰撞
	if not has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12, 12)
		col.shape = shape
		add_child(col)

	# RayCast
	_ray = RayCast2D.new()
	_ray.name = "RayCast2D"
	_ray.target_position = Vector2(0, TILE_SIZE)
	_ray.enabled = true
	add_child(_ray)

	# Camera
	_camera = Camera2D.new()
	_camera.name = "Camera2D"
	add_child(_camera)

	# 角色圖層（由下到上）
	var layers := ["Body", "Eyes", "Outfit", "Hairstyle", "Accessory"]
	for i in layers.size():
		var sprite := Sprite2D.new()
		sprite.name = layers[i]
		sprite.hframes = CHAR_HFRAMES
		sprite.vframes = CHAR_VFRAMES
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = true
		sprite.z_index = i
		add_child(sprite)
		_char_sprites.append(sprite)

	# 工具圖層（最上層）
	_tool_sprite = Sprite2D.new()
	_tool_sprite.name = "Tool"
	_tool_sprite.hframes = TOOL_HFRAMES
	_tool_sprite.vframes = TOOL_VFRAMES
	_tool_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tool_sprite.centered = true
	_tool_sprite.z_index = layers.size()
	_tool_sprite.visible = false
	add_child(_tool_sprite)

	# AnimationPlayer
	_anim_player = AnimationPlayer.new()
	_anim_player.name = "AnimationPlayer"
	add_child(_anim_player)
	_anim_player.animation_finished.connect(_on_animation_finished)


# ════════════════════════════════════════════════════════════
#  動畫建立
# ════════════════════════════════════════════════════════════

func _build_all_animations() -> void:
	var lib := AnimationLibrary.new()
	for anim_name: String in ANIMS:
		var data: Dictionary = ANIMS[anim_name]
		for dir_idx in 4:
			var dir_name: String = ["down", "right", "up", "left"][dir_idx]
			var full_name: String = "%s_%s" % [anim_name, dir_name]
			lib.add_animation(full_name, _make_anim(data, dir_idx))
	_anim_player.add_animation_library("", lib)


func _make_anim(data: Dictionary, dir_idx: int) -> Animation:
	var anim := Animation.new()
	var fpd: int = data.fpd
	var fps: float = data.fps
	anim.length = float(fpd) / fps
	anim.loop_mode = Animation.LOOP_LINEAR if data.loop else Animation.LOOP_NONE

	# ── 角色幀軌道 ──
	# 佈局：一列 = Down(fpd) + Right(fpd) + Up(fpd) + Left(fpd)
	var ct := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(ct, ".:char_frame")
	anim.track_set_interpolation_type(ct, Animation.INTERPOLATION_NEAREST)
	anim.value_track_set_update_mode(ct, Animation.UPDATE_DISCRETE)
	var char_base: int = data.char_row * CHAR_HFRAMES + dir_idx * fpd
	for f in fpd:
		anim.track_insert_key(ct, float(f) / fps, char_base + f)

	# ── 工具幀軌道 ──
	if data.tool_row >= 0:
		var tt := anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(tt, ".:tool_frame")
		anim.track_set_interpolation_type(tt, Animation.INTERPOLATION_NEAREST)
		anim.value_track_set_update_mode(tt, Animation.UPDATE_DISCRETE)
		var tool_base: int = data.tool_row * TOOL_HFRAMES + dir_idx * fpd
		for f in fpd:
			anim.track_insert_key(tt, float(f) / fps, tool_base + f)

	return anim


# ════════════════════════════════════════════════════════════
#  外觀更新
# ════════════════════════════════════════════════════════════

func _refresh_textures() -> void:
	var cm = CharacterManager
	_char_sprites[0].texture = cm.get_texture("body", cm.body)
	_char_sprites[1].texture = cm.get_texture("eyes", cm.eyes)
	_char_sprites[2].texture = cm.get_texture("outfit", cm.outfit)
	_char_sprites[3].texture = cm.get_texture("hairstyle", cm.hairstyle)
	_char_sprites[4].texture = cm.get_texture("accessory", cm.accessory)


func _on_tool_changed(_tool_name: String) -> void:
	if CharacterManager.current_tool == "None":
		_tool_sprite.visible = false
	else:
		_tool_sprite.texture = CharacterManager.get_texture("tool", CharacterManager.current_tool)
		_tool_sprite.visible = ANIMS[_current_anim].needs_tool
	_play(_current_anim)


# ════════════════════════════════════════════════════════════
#  動畫播放
# ════════════════════════════════════════════════════════════

func _play(anim_name: String) -> void:
	_current_anim = anim_name
	var dir_name: String = ["down", "right", "up", "left"][_direction]
	var full: String = "%s_%s" % [anim_name, dir_name]

	var data: Dictionary = ANIMS[anim_name]
	var show_tool: bool = data.needs_tool and CharacterManager.current_tool != "None"
	_tool_sprite.visible = show_tool

	if _anim_player.has_animation(full):
		_anim_player.play(full)


func _on_animation_finished(anim_name: StringName) -> void:
	# 動作結束後回到 idle
	if _is_acting:
		_is_acting = false
		_play("idle")


# ════════════════════════════════════════════════════════════
#  輸入處理
# ════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if DialogueManager.is_active:
		return

	# ── 工具快速鍵 1-4, 0=收起 ──
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: CharacterManager.set_tool("Axe")
			KEY_2: CharacterManager.set_tool("Shovel")
			KEY_3: CharacterManager.set_tool("Watering_Can")
			KEY_4: CharacterManager.set_tool("Fishing_Rod")
			KEY_0: CharacterManager.set_tool("None")

	# ── 工具動作（Z 鍵）──
	if not _is_acting and not _is_moving:
		if event.is_action_pressed("interact"):
			_try_tool_action()
			return

	# ── 移動 ──
	if _is_moving or _is_acting:
		return
	var dir := _get_input_direction()
	if dir != Vector2.ZERO:
		_try_move(dir)


func _get_input_direction() -> Vector2:
	if Input.is_action_pressed("ui_down"):  return Vector2.DOWN
	if Input.is_action_pressed("ui_up"):    return Vector2.UP
	if Input.is_action_pressed("ui_left"):  return Vector2.LEFT
	if Input.is_action_pressed("ui_right"): return Vector2.RIGHT
	return Vector2.ZERO


func _process(_delta: float) -> void:
	if DialogueManager.is_active or _is_moving or _is_acting:
		return
	var dir := _get_input_direction()
	if dir != Vector2.ZERO:
		_try_move(dir)


# ════════════════════════════════════════════════════════════
#  移動
# ════════════════════════════════════════════════════════════

func _try_move(dir: Vector2) -> void:
	_update_direction(dir)

	_ray.target_position = dir * TILE_SIZE
	_ray.force_raycast_update()

	if _ray.is_colliding():
		_play("idle")
		return

	_is_moving = true
	_play("walk")
	var tween := create_tween()
	tween.tween_property(self, "position", position + dir * TILE_SIZE, MOVE_DURATION)
	tween.finished.connect(_on_move_finished)


func _on_move_finished() -> void:
	_is_moving = false
	if _get_input_direction() == Vector2.ZERO:
		_play("idle")


func _update_direction(dir: Vector2) -> void:
	if dir == Vector2.DOWN:  _direction = Dir.DOWN
	elif dir == Vector2.RIGHT: _direction = Dir.RIGHT
	elif dir == Vector2.UP:    _direction = Dir.UP
	elif dir == Vector2.LEFT:  _direction = Dir.LEFT


# ════════════════════════════════════════════════════════════
#  工具動作
# ════════════════════════════════════════════════════════════

func _try_tool_action() -> void:
	var tool_name: String = CharacterManager.current_tool
	if tool_name == "None" or tool_name not in TOOL_ACTION:
		return
	_is_acting = true
	_play(TOOL_ACTION[tool_name])
