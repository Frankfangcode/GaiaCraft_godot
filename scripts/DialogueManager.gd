extends Node

signal dialogue_ended

var is_active := false

var _canvas_layer: CanvasLayer
var _panel: Panel
var _label: Label

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 10
	add_child(_canvas_layer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -120
	_panel.offset_left = 16
	_panel.offset_right = -16
	_panel.offset_bottom = -8
	_panel.visible = false
	_canvas_layer.add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.9)
	style.border_color = Color(0.8, 0.8, 0.9, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 16
	_label.offset_top = 12
	_label.offset_right = -16
	_label.offset_bottom = -12
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_label)

func show_dialogue(text: String) -> void:
	_label.text = text
	_panel.visible = true
	is_active = true

func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("interact"):
		_panel.visible = false
		is_active = false
		get_viewport().set_input_as_handled()
		dialogue_ended.emit()
