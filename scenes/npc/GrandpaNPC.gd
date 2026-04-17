extends StaticBody2D
## 阿公 NPC — 開場任務 & 結尾演出

var can_interact := false
var _stage := 0   # 0=開場, 1=水位降後, 2=拿到鐵茶罐後
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

	_update_stage()
	_speak()
	_prompt.visible = false

func _update_stage() -> void:
	if InventoryManager.has_item("Iron_Tea_Can"):
		_stage = 2
	elif InventoryManager.has_item("Turtle_Blessing"):
		_stage = 1

func _speak() -> void:
	match _stage:
		0:
			DialogueManager.show_dialogue(
				"阿安啊，阿公今天腳不太好，走不過去。\n" +
				"你幫阿公去做三件事——\n" +
				"取回鐵罐、看看老學校、找到牆上那份名冊。\n" +
				"那是我們家族的根。")
		1:
			DialogueManager.show_dialogue(
				"你看，浮出來了。\n" +
				"每次枯水期，我就站在這裡看。\n" +
				"那個屋頂，是阿公家。")
		2:
			DialogueManager.show_dialogue(
				"聞到了。還是一樣的味道。\n" +
				"你曾祖父說，包種茶是文山的魂。\n" +
				"現在魂還在，就夠了。")

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = true
		if not DialogueManager.is_active:
			_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		can_interact = false
		_prompt.visible = false
