extends StaticBody2D
## 食蛇龜 Coco — 解救互動，給予「龜的祝福」道具

var can_interact := false
var _stage := 0   # 0=被困, 1=詢問後等解救, 2=已獲救
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

	match _stage:
		0:
			_stage = 1
			DialogueManager.show_dialogue(
				"咦——你是新來的人類嗎？\n" +
				"這個罐子卡很緊，可以幫我嗎？")
		1:
			_stage = 2
			InventoryManager.add_item("Turtle_Blessing")
			DialogueManager.show_dialogue(
				"謝謝你。我在這山裡住了好幾十年。\n" +
				"以前人很多，熱鬧得很。後來水來了，人都走了，就剩我們還在。\n\n" +
				"你要去找老村莊？帶著我的祝福去吧。\n" +
				"水位計要用龜的氣息才能打開——是老輩人設計的機關。\n\n" +
				"【獲得：龜的祝福】")
		2:
			DialogueManager.show_dialogue(
				"（Coco 點點頭）去吧，我在這裡等你回來。")
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
