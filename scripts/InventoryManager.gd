extends Node

var items: Array[String] = []

# Item database: icon_frame is index into Icons.png (16x5 grid, 32x32 per cell)
var item_data := {
	"Student_ID": {
		"name": "學生證",
		"description": "政大的通行證，上面有澤享的照片。",
		"icon_frame": 22,
	},
	"Umbrella": {
		"name": "雨傘",
		"description": "文山區必備。雖然政大常下雨，但這把傘好像有點漏水。",
		"icon_frame": 37,
	},
}

func add_item(item_name: String) -> void:
	if not items.has(item_name):
		items.append(item_name)

func has_item(item_name: String) -> bool:
	return items.has(item_name)

func get_item_data(item_name: String) -> Dictionary:
	if item_data.has(item_name):
		return item_data[item_name]
	return {}
