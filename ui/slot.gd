extends Button

# Ссылка на инвентарь и свой индекс, чтобы знать, что менять
var inventory_ref: Inventory
var index: int

# Функция инициализации (вызовем её из InventoryUI)
func set_slot_data(new_inventory: Inventory, new_index: int, slot_data: SlotData):
	inventory_ref = new_inventory
	index = new_index
	
	var icon_node = $Icon
	var quantity_label = $QuantityLabel
	
	if slot_data and slot_data.item_data:
		icon_node.texture = slot_data.item_data.icon
		tooltip_text = "%s\n%s" % [slot_data.item_data.name, slot_data.item_data.description]
		
		if slot_data.quantity > 1:
			quantity_label.text = "x%d" % slot_data.quantity
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		icon_node.texture = null
		quantity_label.visible = false
		tooltip_text = ""

# --- DRAG & DROP LOGIC ---

func _get_drag_data(at_position: Vector2):
	var slot_data = inventory_ref.get_slot_data(index)
	if not slot_data: return null
	
	var preview = TextureRect.new()
	preview.texture = slot_data.item_data.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(40, 40)
	set_drag_preview(preview)
	
	# ИЗМЕНЕНИЕ: Передаем ссылку на inventory_ref (откуда тащим)
	return { 
		"index": index,
		"origin_inventory": inventory_ref 
	}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("index") and data.has("origin_inventory")

func _drop_data(at_position: Vector2, data: Variant):
	var origin_index = data["index"]
	var origin_inventory = data["origin_inventory"]
	var target_index = index
	var target_inventory = inventory_ref # Инвентарь, которому принадлежит ЭТОТ слот (куда бросаем)
	
	# Вызываем новую функцию transfer_slot У ИСХОДНОГО инвентаря
	origin_inventory.transfer_slot(origin_index, target_inventory, target_index)