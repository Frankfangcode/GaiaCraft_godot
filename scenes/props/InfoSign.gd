extends StaticBody2D
## 通用資訊招牌 — 設定圖片、標題、說明文字即可

@export var sign_texture: Texture2D
@export var sign_title: String = "招牌"
@export_multiline var sign_description: String = ""

var can_interact := false
var _prompt: Label

func _ready() -> void:
	if sign_texture:
		$Sprite2D.texture = sign_texture
	$InteractZone.body_entered.connect(_on_body_entered)
	$InteractZone.body_exited.connect(_on_body_exited)
	_create_prompt()

func _create_prompt() -> void:
	_prompt = Label.new()
	_prompt.text = "Z"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.position = Vector2(-10, -30)
	_prompt.add_theme_font_size_override("font_size", 12)
	_prompt.add_theme_color_override("font_color", Color.WHITE)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 3)
	_prompt.visible = false
	add_child(_prompt)

func _unhandled_input(event: InputEvent) -> void:
	if not can_interact:
		return
	if not event.is_action_pressed("interact"):
		return
	if DialogueManager.is_active:
		return
	_prompt.visible = false
	DialogueManager.show_dialogue("【%s】\n\n%s" % [sign_title, sign_description])

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = true
		if not DialogueManager.is_active:
			_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = false
		_prompt.visible = false
