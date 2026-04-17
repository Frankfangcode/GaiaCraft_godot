extends StaticBody2D
## 水位計 — 需要「龜的祝福」才能啟動，觸發傳送至水下場景

var can_interact := false
var _activated := false
var _prompt: Label

func _ready() -> void:
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

	if _activated:
		SceneChanger.change_scene_with_video(
			"res://assets/video/transition_water.ogv",
			"res://scenes/main/WatermapScene.tscn",
			Vector2(800, 120))
		return

	if InventoryManager.has_item("Turtle_Blessing"):
		_activated = true
		DialogueManager.show_dialogue(
			"水位計緩緩啟動……\n" +
			"水面從眼前退去，露出長滿水草的廢墟屋頂。\n\n" +
			"沉沒的碧山村，浮現了。")
		# 對話結束後傳送
		await DialogueManager.dialogue_ended
		SceneChanger.change_scene_with_video(
			"res://assets/video/transition_water.ogv",
			"res://scenes/main/WatermapScene.tscn",
			Vector2(800, 120))
	else:
		DialogueManager.show_dialogue(
			"水位計上刻著奇特的符文。\n" +
			"似乎需要某種特殊的氣息才能啟動……")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = true
		if not DialogueManager.is_active:
			_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = false
		_prompt.visible = false
