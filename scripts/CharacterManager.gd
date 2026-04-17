extends Node
## ============================================================
## 角色外觀 & 工具管理器 (Autoload)
## 儲存角色當前的所有外觀設定與手持工具狀態
## ============================================================

const BASE := "res://assets/tilesets/Modern_Farm_v1/Farmer_Generator_Pieces/"
const CHAR_BASE := BASE + "Character Pieces/"
const TOOL_BASE := BASE + "Tools/"

## 解析度：可切換 "16x16", "32x32", "48x48"
var resolution: String = "16x16"

# ─── 當前外觀 ───
var body: String = "Body_1"
var eyes: String = "Eyes_Brown"
var outfit: String = "Outfit_Dungarees_Blue"
var hairstyle: String = "Hairstyle_Short_Brown_Dark"
var accessory: String = ""

# ─── 當前工具 ───
var current_tool: String = "None"  ## None, Axe, Shovel, Watering_Can, Fishing_Rod

# ─── 信號 ───
signal appearance_changed
signal tool_changed(tool_name: String)

# ─── 可用選項（供 Creator UI 使用）───
var body_options := [
	"Body_1", "Body_2", "Body_3", "Body_4", "Body_5",
	"Body_6", "Body_7", "Body_8", "Body_9"]
var eyes_options := [
	"Eyes_Blue", "Eyes_Brown", "Eyes_Gray", "Eyes_Green", "Eyes_Orange"]
var hairstyle_options := [
	"Hairstyle_Short_Blonde", "Hairstyle_Short_Brown_Dark",
	"Hairstyle_Short_Brown_Light", "Hairstyle_Short_Orange",
	"Hairstyle_Long_Blonde", "Hairstyle_Long_Brown_Dark",
	"Hairstyle_Tuft_Blonde", "Hairstyle_Tuft_Brown_Dark",
	"Hairstyle_Unkept_Blonde", "Hairstyle_Unkept_Brown_Dark",
	"Hairstyle_Balding_Gray", "Hairstyle_Balding_Brown_Dark"]
var outfit_options := [
	"Outfit_Dungarees_Blue", "Outfit_Dungarees_Red",
	"Outfit_Dungarees_Green", "Outfit_Dungarees_Yellow",
	"Outfit_Braces_Blue", "Outfit_Braces_Red", "Outfit_Braces_Green",
	"Outfit_Laborer_Blue", "Outfit_Laborer_Red", "Outfit_Laborer_Green",
	"Outfit_Vest_Blue", "Outfit_Vest_Red", "Outfit_Vest_Green"]
var accessory_options := [
	"", "Accessory_Straw_Hat_Green", "Accessory_Straw_Hat_Cyan",
	"Accessory_Straw_Hat_Violet", "Accessory_Straw_Hat_Black",
	"Accessory_Bamboo_Hat_Brown", "Accessory_Bamboo_Hat_Brown_Dull",
	"Accessory_Gas_Mask"]
var tool_options := ["None", "Axe", "Shovel", "Watering_Can", "Fishing_Rod"]


# ─── 外觀設定 ───

func set_body(name: String) -> void:
	body = name
	appearance_changed.emit()

func set_eyes(name: String) -> void:
	eyes = name
	appearance_changed.emit()

func set_outfit(name: String) -> void:
	outfit = name
	appearance_changed.emit()

func set_hairstyle(name: String) -> void:
	hairstyle = name
	appearance_changed.emit()

func set_accessory(name: String) -> void:
	accessory = name
	appearance_changed.emit()

func set_tool(name: String) -> void:
	current_tool = name
	tool_changed.emit(name)

func update_player_visuals() -> void:
	appearance_changed.emit()


# ─── 圖片載入 ───

func get_texture(category: String, asset_name: String) -> Texture2D:
	if asset_name.is_empty():
		return null
	var path := _build_path(category, asset_name)
	if path.is_empty():
		return null
	# 嘗試 Godot 匯入系統
	var tex: Texture2D = load(path)
	if tex:
		return tex
	# 備案：直接從磁碟載入
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.load_from_file(abs_path)
	if img:
		return ImageTexture.create_from_image(img)
	push_warning("CharacterManager: 無法載入 %s" % path)
	return null


func _build_path(category: String, asset_name: String) -> String:
	match category:
		"body":
			return CHAR_BASE + "Bodies/%s/%s.png" % [resolution, asset_name]
		"eyes":
			return CHAR_BASE + "Eyes/%s/%s.png" % [resolution, asset_name]
		"outfit":
			return CHAR_BASE + "Outfits/%s/%s.png" % [resolution, asset_name]
		"hairstyle":
			return CHAR_BASE + "Hairstyles/%s/%s.png" % [resolution, asset_name]
		"accessory":
			return CHAR_BASE + "Accessories/%s/%s.png" % [resolution, asset_name]
		"tool":
			return TOOL_BASE + "%s/Tool_%s.png" % [resolution, asset_name]
	return ""


func cycle_option(options: Array, current: String, delta: int) -> String:
	var idx := options.find(current)
	if idx < 0:
		idx = 0
	idx = (idx + delta) % options.size()
	if idx < 0:
		idx += options.size()
	return options[idx]
