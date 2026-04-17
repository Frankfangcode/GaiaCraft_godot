@tool
extends Area2D

## Icons.png spritesheet: 512x160, 16 cols x 5 rows, 32x32 per cell
@export_range(0, 79) var icon_frame: int = 0:
	set(value):
		icon_frame = value
		_update_sprite()

@export var plant_name: String = "植物"
@export_multiline var plant_description: String = ""

var _can_interact := false
var _prompt: Label

const ICON_COLS := 16
const ICON_SIZE := 32
var _icons_tex: Texture2D

func _ready() -> void:
	_icons_tex = load("res://assets/tilesets/Modern_Farm_v1/RPG_Maker_MV/Icons.png")
	_update_sprite()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_prompt()
	_start_float_anim()

func _update_sprite() -> void:
	if not is_inside_tree():
		await ready
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		return
	if not _icons_tex:
		_icons_tex = load("res://assets/tilesets/Modern_Farm_v1/RPG_Maker_MV/Icons.png")
	if not _icons_tex:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = _icons_tex
	var col := icon_frame % ICON_COLS
	var row := icon_frame / ICON_COLS
	atlas.region = Rect2(col * ICON_SIZE, row * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	sprite.texture = atlas

func _start_float_anim() -> void:
	var sprite := $Sprite2D as Sprite2D
	var base_y := sprite.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", base_y - 3.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", base_y, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _create_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = "[Z] 導覽"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(-28, -36)
	_prompt.add_theme_font_size_override("font_size", 10)
	_prompt.add_theme_color_override("font_color", Color.WHITE)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.visible = false
	add_child(_prompt)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if _can_interact and event.is_action_pressed("interact") and not DialogueManager.is_active:
		DialogueManager.show_dialogue("【校園植物：%s】\n\n%s" % [plant_name, plant_description])
		_prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_can_interact = true
		if not DialogueManager.is_active:
			_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_can_interact = false
		_prompt.visible = false
