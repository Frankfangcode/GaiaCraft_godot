extends Node

var is_open := false

var _canvas_layer: CanvasLayer
var _panel: PanelContainer
var _grid: GridContainer
var _desc_label: Label
var _icons_texture: Texture2D

const GRID_COLS := 4
const GRID_SLOTS := 16
const ICON_SIZE := 32

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_icons_texture = load("res://assets/tilesets/Modern_Farm_v1/RPG_Maker_MV/Icons.png")
	_build_ui()

func _build_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 15
	add_child(_canvas_layer)

	var control := Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(control)

	# --- Centered panel ---
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(280, 360)
	_panel.offset_left = -140
	_panel.offset_right = 140
	_panel.offset_top = -180
	_panel.offset_bottom = 180

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.94)
	style.border_color = Color(0.6, 0.55, 0.4, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)
	control.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	# --- Title ---
	var title := Label.new()
	title.text = "道具清單"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	vbox.add_child(title)

	# --- Grid ---
	_grid = GridContainer.new()
	_grid.columns = GRID_COLS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_grid)

	# --- Separator ---
	vbox.add_child(HSeparator.new())

	# --- Description ---
	_desc_label = Label.new()
	_desc_label.text = "選擇一個道具查看描述..."
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0, 52)
	_desc_label.add_theme_font_size_override("font_size", 13)
	_desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(_desc_label)

	_panel.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	is_open = not is_open
	_panel.visible = is_open
	get_tree().paused = is_open
	if is_open:
		_refresh_grid()
		_desc_label.text = "選擇一個道具查看描述..."

func _refresh_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	# Wait one frame for queue_free to take effect
	await get_tree().process_frame
	for i in range(GRID_SLOTS):
		_grid.add_child(_create_slot(i))

func _create_slot(index: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(56, 56)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	normal_style.border_color = Color(0.4, 0.4, 0.5, 0.6)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(2)
	normal_style.set_content_margin_all(4)
	slot.add_theme_stylebox_override("panel", normal_style)

	var tex_rect := TextureRect.new()
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tex_rect.custom_minimum_size = Vector2(48, 48)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(tex_rect)

	# Fill slot if item exists at this index
	if index < InventoryManager.items.size():
		var item_name: String = InventoryManager.items[index]
		var data: Dictionary = InventoryManager.get_item_data(item_name)
		if data.size() > 0:
			tex_rect.texture = _make_icon(data["icon_frame"])

			# Hover highlight
			var hover_style := normal_style.duplicate()
			hover_style.border_color = Color(1.0, 0.85, 0.3, 1.0)
			hover_style.set_border_width_all(2)

			slot.mouse_entered.connect(func():
				slot.add_theme_stylebox_override("panel", hover_style)
			)
			slot.mouse_exited.connect(func():
				slot.add_theme_stylebox_override("panel", normal_style)
			)

			# Click to show description
			slot.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					_desc_label.text = data["name"] + "：" + data["description"]
			)

	return slot

func _make_icon(frame_index: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _icons_texture
	var col := frame_index % 16
	var row := frame_index / 16
	atlas.region = Rect2(col * ICON_SIZE, row * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	return atlas
