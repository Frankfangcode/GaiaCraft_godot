@tool
extends EditorScript
## ============================================================
## GameMaker 47-tile Blob Autotile → Godot 4 TileSet 自動建立腳本
## 使用方式：在 Godot 編輯器中 File > Run (Ctrl+Shift+X)
## ============================================================

# ─── 可修改設定 ─────────────────────────────────────────────
const TEXTURE_PATH := "res://assets/tilesets/Modern_Farm_v1/16x16/Autotiles_16x16/Autotiles_GameMaker_16x16.png"
const OUTPUT_PATH  := "res://assets/tilesets/autotile_tileset.tres"
const TILE_PX      := 16
const ATLAS_COLS   := 12
const ROWS_PER_TERRAIN := 4

## 需要物理碰撞的地形索引（從 0 開始）
## 例如：水=3，可依實際情況調整
const OBSTACLE_TERRAINS: Array[int] = [3]

## 地形名稱（可自訂，數量需 ≤ 圖片中的地形數）
const TERRAIN_NAMES := [
	"草地",       # 0
	"泥土路",     # 1
	"水池",       # 2
	"深水",       # 3
	"沙灘",       # 4
	"農田",       # 5
	"淺灘",       # 6
	"河流",       # 7
	"耕地",       # 8
	"石板",       # 9
	"圍籬",       # 10
	"花圃",       # 11
	"荒地",       # 12
	"柵欄",       # 13
]

# ─── GameMaker 47-Blob 位元對照表 ──────────────────────────
# 位元定義（鄰居方位）：
#   NW=1   N=2   NE=4
#   W=8    ■     E=16
#   SW=32  S=64  SE=128
#
# 規則：角落(NW/NE/SW/SE)僅在相鄰兩邊都存在時才有效
# 例如 NW 只有在 N 和 W 都存在時才算
#
# 排列：12 欄 × 4 列 = 48 格，前 47 格是有效 tile，第 48 格空白
# ────────────────────────────────────────────────────────────
const GM47_BITMASKS := [
	# ── Row 0：四邊皆有，變化四角 ──
	255,  # (0,0)  全包圍
	127,  # (1,0)  缺 SE
	223,  # (2,0)  缺 SW
	95,   # (3,0)  缺 SW+SE
	251,  # (4,0)  缺 NE
	123,  # (5,0)  缺 NE+SE
	219,  # (6,0)  缺 NE+SW
	91,   # (7,0)  缺 NE+SW+SE
	254,  # (8,0)  缺 NW
	126,  # (9,0)  缺 NW+SE
	222,  # (10,0) 缺 NW+SW
	94,   # (11,0) 缺 NW+SW+SE

	# ── Row 1：四邊皆有(續) + 缺一邊 ──
	250,  # (0,1)  缺 NW+NE
	122,  # (1,1)  缺 NW+NE+SE
	218,  # (2,1)  缺 NW+NE+SW
	90,   # (3,1)  缺四角（僅四邊）
	31,   # (4,1)  缺 S  有 NW+NE
	30,   # (5,1)  缺 S  有 NE
	27,   # (6,1)  缺 S  有 NW
	26,   # (7,1)  缺 S  無角
	248,  # (8,1)  缺 N  有 SW+SE
	216,  # (9,1)  缺 N  有 SE
	120,  # (10,1) 缺 N  有 SW
	88,   # (11,1) 缺 N  無角

	# ── Row 2：缺一邊(續) + L 形(缺兩鄰邊) ──
	214,  # (0,2)  缺 W  有 NE+SE
	210,  # (1,2)  缺 W  有 SE
	86,   # (2,2)  缺 W  有 NE
	82,   # (3,2)  缺 W  無角
	107,  # (4,2)  缺 E  有 NW+SW
	106,  # (5,2)  缺 E  有 SW
	75,   # (6,2)  缺 E  有 NW
	74,   # (7,2)  缺 E  無角
	22,   # (8,2)  N+E  有 NE
	18,   # (9,2)  N+E  無角
	11,   # (10,2) N+W  有 NW
	10,   # (11,2) N+W  無角

	# ── Row 3：L 形(續) + 走廊 + 端點 + 孤島 ──
	208,  # (0,3)  S+E  有 SE
	80,   # (1,3)  S+E  無角
	104,  # (2,3)  S+W  有 SW
	72,   # (3,3)  S+W  無角
	66,   # (4,3)  N+S  直走廊
	24,   # (5,3)  E+W  橫走廊
	2,    # (6,3)  N    北端點
	16,   # (7,3)  E    東端點
	64,   # (8,3)  S    南端點
	8,    # (9,3)  W    西端點
	0,    # (10,3) 孤島（無鄰居）
]

# ─── 位元 → Godot CellNeighbor 對應 ──────────────────────
# TileSet.CellNeighbor enum (square tiles):
#   RIGHT_SIDE=0, BOTTOM_RIGHT_CORNER=3, BOTTOM_SIDE=4,
#   BOTTOM_LEFT_CORNER=7, LEFT_SIDE=8, TOP_LEFT_CORNER=11,
#   TOP_SIDE=12, TOP_RIGHT_CORNER=15
const BIT_TO_PEERING := {
	1:   11,  # NW → TOP_LEFT_CORNER
	2:   12,  # N  → TOP_SIDE
	4:   15,  # NE → TOP_RIGHT_CORNER
	8:   8,   # W  → LEFT_SIDE
	16:  0,   # E  → RIGHT_SIDE
	32:  7,   # SW → BOTTOM_LEFT_CORNER
	64:  4,   # S  → BOTTOM_SIDE
	128: 3,   # SE → BOTTOM_RIGHT_CORNER
}


func _run() -> void:
	# 先嘗試觸發檔案系統掃描（讓 Godot 匯入尚未匯入的圖片）
	EditorInterface.get_resource_filesystem().scan()

	var texture: Texture2D = load(TEXTURE_PATH) as Texture2D
	if not texture:
		# 備案：直接從磁碟載入 PNG（繞過 Godot 匯入系統）
		print("load() 失敗，嘗試直接從磁碟載入...")
		var abs_path := ProjectSettings.globalize_path(TEXTURE_PATH)
		var img := Image.load_from_file(abs_path)
		if img == null:
			printerr("無法載入圖片：", TEXTURE_PATH)
			printerr("請確認檔案存在於: ", abs_path)
			return
		texture = ImageTexture.create_from_image(img)
		print("已從磁碟直接載入圖片（注意：TileSet 將內嵌圖片資料）")

	var img_h := texture.get_height()
	var total_rows := img_h / TILE_PX
	var num_terrains := total_rows / ROWS_PER_TERRAIN

	print("=== Autotile TileSet 建立開始 ===")
	print("  圖片大小: %dx%d" % [texture.get_width(), img_h])
	print("  地形數量: %d" % num_terrains)

	# ─── 建立 TileSet ───
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_PX, TILE_PX)

	# 物理層（碰撞用）
	tileset.add_physics_layer()

	# 地形集：Match Corners and Sides (3x3 Minimal)
	tileset.add_terrain_set()
	tileset.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)

	# 建立地形定義
	for i in num_terrains:
		tileset.add_terrain(0)
		var tname: String
		if i < TERRAIN_NAMES.size():
			tname = TERRAIN_NAMES[i]
		else:
			tname = "Terrain_%d" % i
		tileset.set_terrain_name(0, i, tname)
		tileset.set_terrain_color(0, i, Color.from_hsv(float(i) / num_terrains, 0.7, 0.9))

	# ─── 建立 Atlas Source ───
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	var source_id := tileset.add_source(source)

	# ─── 為每個地形建立 47 個 Tile 並設定 Peering Bits ───
	var collision_half := TILE_PX / 2.0
	var collision_rect := PackedVector2Array([
		Vector2(-collision_half, -collision_half),
		Vector2( collision_half, -collision_half),
		Vector2( collision_half,  collision_half),
		Vector2(-collision_half,  collision_half),
	])

	for terrain_idx in num_terrains:
		var base_row := terrain_idx * ROWS_PER_TERRAIN

		for tile_i in GM47_BITMASKS.size():
			var col := tile_i % ATLAS_COLS
			var row := base_row + tile_i / ATLAS_COLS
			var coords := Vector2i(col, row)

			# 建立 tile
			source.create_tile(coords)
			var td := source.get_tile_data(coords, 0)

			# 設定地形歸屬
			td.terrain_set = 0
			td.terrain = terrain_idx

			# 設定 Peering Bits
			var bitmask: int = GM47_BITMASKS[tile_i]
			for bit: int in BIT_TO_PEERING:
				if bitmask & bit:
					td.set_terrain_peering_bit(bit_to_cell_neighbor(BIT_TO_PEERING[bit]), terrain_idx)

			# 障礙物碰撞
			if terrain_idx in OBSTACLE_TERRAINS:
				td.set_collision_polygons_count(0, 1)
				td.set_collision_polygon_points(0, 0, collision_rect)

	# ─── 儲存 ───
	var err := ResourceSaver.save(tileset, OUTPUT_PATH)
	if err == OK:
		print("=== TileSet 建立完成 ===")
		print("  儲存位置: %s" % OUTPUT_PATH)
		print("  地形數量: %d" % num_terrains)
		print("  每地形 Tile: %d" % GM47_BITMASKS.size())
		print("  碰撞地形: %s" % str(OBSTACLE_TERRAINS))
		print("")
		print("下一步：")
		print("  1. 在 FileSystem 中雙擊 %s 開啟 TileSet" % OUTPUT_PATH)
		print("  2. 建立 TileMapLayer 節點，指定此 TileSet")
		print("  3. 使用地形筆刷 (Terrain tab) 繪製地圖")
	else:
		printerr("儲存失敗，錯誤碼: ", err)


## 將整數轉為 TileSet.CellNeighbor enum
func bit_to_cell_neighbor(value: int) -> TileSet.CellNeighbor:
	return value as TileSet.CellNeighbor
