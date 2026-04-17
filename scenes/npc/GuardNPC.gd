extends StaticBody2D

var can_interact := false
var gate_opened := false
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
	if can_interact and event.is_action_pressed("interact") and not DialogueManager.is_active:
		if InventoryManager.has_item("Student_ID"):
			DialogueManager.show_dialogue("喔！是澤享同學啊，請進！記得雨天路滑要小心喔。")
			if not gate_opened:
				gate_opened = true
				var gate := get_node_or_null("Gate/GateCollision")
				if gate:
					gate.set_deferred("disabled", true)
		else:
			DialogueManager.show_dialogue("同學，沒有學生證不能進去喔！去附近找找看是不是掉在路邊了。")
		_prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = true
		if not DialogueManager.is_active:
			_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = false
		_prompt.visible = false
