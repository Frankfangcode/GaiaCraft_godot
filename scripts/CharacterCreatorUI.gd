extends Node
## ============================================================
## 角色客製化 UI + 工具快速切換顯示 (Autoload)
## 按 C 鍵開啟角色編輯器
## ============================================================

var _canvas: CanvasLayer
var _center: CenterContainer
var _panel: PanelContainer
var _visible := false

# 各選項的 Label（顯示目前名稱）
var _labels := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_center.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_toggle()


func _toggle() -> void:
	_visible = not _visible
	_center.visible = _visible
	get_tree().paused = _visible
	if _visible:
		_refresh_labels()


# ════════════════════════════════════════════════════════════
#  UI 建構
# ════════════════════════════════════════════════════════════

func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 16
	_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas)

	# 全螢幕置中容器
	_center = CenterContainer.new()
	_center.process_mode = Node.PROCESS_MODE_ALWAYS
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_center)

	_panel = PanelContainer.new()
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.custom_minimum_size = Vector2(320, 0)
	# 背景樣式
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	_center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# 標題
	var title := Label.new()
	title.text = "角色客製化"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)

	# 分隔線
	vbox.add_child(HSeparator.new())

	# 外觀選項列
	_add_row(vbox, "膚色", "body", CharacterManager.body_options,
		func(): return CharacterManager.body,
		func(v: String): CharacterManager.set_body(v))

	_add_row(vbox, "眼睛", "eyes", CharacterManager.eyes_options,
		func(): return CharacterManager.eyes,
		func(v: String): CharacterManager.set_eyes(v))

	_add_row(vbox, "髮型", "hairstyle", CharacterManager.hairstyle_options,
		func(): return CharacterManager.hairstyle,
		func(v: String): CharacterManager.set_hairstyle(v))

	_add_row(vbox, "服裝", "outfit", CharacterManager.outfit_options,
		func(): return CharacterManager.outfit,
		func(v: String): CharacterManager.set_outfit(v))

	_add_row(vbox, "配件", "accessory", CharacterManager.accessory_options,
		func(): return CharacterManager.accessory,
		func(v: String): CharacterManager.set_accessory(v))

	# 分隔
	vbox.add_child(HSeparator.new())

	# 工具提示
	var tool_hint := Label.new()
	tool_hint.text = "工具快速鍵：\n  1=斧頭  2=鏟子  3=澆水壺  4=釣竿  0=收起"
	tool_hint.add_theme_font_size_override("font_size", 11)
	tool_hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(tool_hint)

	# 當前工具顯示
	_add_row(vbox, "工具", "tool", CharacterManager.tool_options,
		func(): return CharacterManager.current_tool,
		func(v: String): CharacterManager.set_tool(v))

	# 關閉提示
	vbox.add_child(HSeparator.new())
	var close := Label.new()
	close.text = "按 C 關閉"
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.add_theme_font_size_override("font_size", 11)
	close.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(close)


func _add_row(parent: VBoxContainer, label_text: String, key: String,
		options: Array, getter: Callable, setter: Callable) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	parent.add_child(hbox)

	# 類別名稱
	var cat := Label.new()
	cat.text = label_text
	cat.custom_minimum_size.x = 50
	cat.add_theme_font_size_override("font_size", 13)
	cat.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(cat)

	# ◀ 按鈕
	var btn_l := Button.new()
	btn_l.text = "<"
	btn_l.custom_minimum_size = Vector2(28, 28)
	hbox.add_child(btn_l)

	# 目前值
	var val_label := Label.new()
	val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_label.add_theme_font_size_override("font_size", 12)
	val_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	val_label.clip_text = true
	hbox.add_child(val_label)
	_labels[key] = val_label

	# ▶ 按鈕
	var btn_r := Button.new()
	btn_r.text = ">"
	btn_r.custom_minimum_size = Vector2(28, 28)
	hbox.add_child(btn_r)

	# 按鈕事件
	btn_l.pressed.connect(func():
		var cur: String = getter.call()
		var next: String = CharacterManager.cycle_option(options, cur, -1)
		setter.call(next)
		_refresh_labels())

	btn_r.pressed.connect(func():
		var cur: String = getter.call()
		var next: String = CharacterManager.cycle_option(options, cur, 1)
		setter.call(next)
		_refresh_labels())


# ════════════════════════════════════════════════════════════
#  標籤更新
# ════════════════════════════════════════════════════════════

func _refresh_labels() -> void:
	_labels["body"].text = _short(CharacterManager.body)
	_labels["eyes"].text = _short(CharacterManager.eyes)
	_labels["hairstyle"].text = _short(CharacterManager.hairstyle)
	_labels["outfit"].text = _short(CharacterManager.outfit)
	var acc: String = CharacterManager.accessory
	_labels["accessory"].text = _short(acc) if not acc.is_empty() else "無"
	_labels["tool"].text = _tool_name(CharacterManager.current_tool)


func _short(s: String) -> String:
	# "Hairstyle_Short_Brown_Dark" → "Short Brown Dark"
	var parts := s.split("_")
	if parts.size() > 1:
		parts.remove_at(0)
	return " ".join(parts)


func _tool_name(t: String) -> String:
	match t:
		"None": return "無"
		"Axe": return "斧頭"
		"Shovel": return "鏟子"
		"Watering_Can": return "澆水壺"
		"Fishing_Rod": return "釣竿"
	return t
