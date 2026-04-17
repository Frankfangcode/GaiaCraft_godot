extends Area2D

@export var item_name: String = ""
@export var icon_frame: int = 22

var _can_pickup := false
var _prompt: Label

func _ready() -> void:
	$Sprite2D.frame = icon_frame
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
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
	if _can_pickup and event.is_action_pressed("interact") and not DialogueManager.is_active:
		InventoryManager.add_item(item_name)
		var data := InventoryManager.get_item_data(item_name)
		var display_name: String = data.get("name", item_name)
		DialogueManager.show_dialogue("撿到了「%s」！" % display_name)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_can_pickup = true
		if not DialogueManager.is_active:
			_prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_can_pickup = false
		_prompt.visible = false
