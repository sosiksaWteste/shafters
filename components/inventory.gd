extends Node
class_name Inventory

signal inventory_updated

@export var capacity: int = 20
# Теперь храним SlotData вместо ItemData
var slots: Array[SlotData] = []

func _ready():
	slots.resize(capacity)
	slots.fill(null)

# Улучшенная функция добавления (с учетом стеков)
func add_item(item: ItemData, amount: int = 1) -> bool:
	# 1. Сначала пробуем добавить в существующие стеки
	for slot in slots:
		if slot and slot.can_merge_with(item):
			amount = slot.merge_with(item, amount)
			inventory_updated.emit()
			if amount == 0:
				return true # Всё влезло
	
	# 2. Если осталось (или предмет не стакается), ищем пустой слот
	while amount > 0:
		var empty_index = slots.find(null)
		if empty_index == -1:
			return false # Инвентарь полон, остаток (amount) не влез
		
		# Создаем новый слот
		var new_slot = SlotData.new()
		new_slot.item_data = item
		# Сколько кладем в новый слот? (не больше макс. стака)
		var take = min(amount, item.max_stack_size)
		new_slot.quantity = take
		slots[empty_index] = new_slot
		amount -= take
		
	inventory_updated.emit()
	return true

# Получить данные слота
func get_slot_data(index: int) -> SlotData:
	if index >= 0 and index < slots.size():
		return slots[index]
	return null

# Удалить предмет из слота (уменьшить количество)
func decrease_item_at(index: int, amount: int = 1):
	var slot = get_slot_data(index)
	if slot:
		slot.quantity -= amount
		if slot.quantity <= 0:
			slots[index] = null # Слот пуст
		inventory_updated.emit()

# Для совместимости со старым кодом (удаляет весь слот)
func remove_slot_at(index: int):
	if index >= 0 and index < slots.size():
		slots[index] = null
		inventory_updated.emit()

func swap_slots(index1: int, index2: int):
	if index1 < 0 or index1 >= slots.size() or index2 < 0 or index2 >= slots.size():
		return
	
	var temp = slots[index1]
	slots[index1] = slots[index2]
	slots[index2] = temp
	
	inventory_updated.emit()

func transfer_slot(from_index: int, target_inventory: Inventory, target_index: int):
	# 1. Получаем данные обоих слотов
	var my_slot = slots[from_index]
	var target_slot = target_inventory.slots[target_index]
	
	# 2. Если мы перетаскиваем в тот же самый инвентарь -> просто меняем местами
	if target_inventory == self:
		swap_slots(from_index, target_index)
		return

	# 3. Логика обмена между РАЗНЫМИ инвентарями
	
	# Сценарий А: Целевой слот пуст -> просто перекладываем
	if target_slot == null:
		target_inventory.slots[target_index] = my_slot
		slots[from_index] = null
		
	# Сценарий Б: В целевом слоте ТАКОЙ ЖЕ предмет -> пытаемся объединить (стакнуть)
	elif my_slot and target_slot and my_slot.can_merge_with(target_slot.item_data):
		# Пытаемся влить my_slot в target_slot
		var remaining = target_slot.merge_with(my_slot.item_data, my_slot.quantity)
		# merge_with возвращает остаток. Обновляем количество в источнике
		my_slot.quantity = remaining
		if my_slot.quantity <= 0:
			slots[from_index] = null # Полностью перенеслось
			
	# Сценарий В: Предметы разные -> меняем местами (Swap)
	else:
		target_inventory.slots[target_index] = my_slot
		slots[from_index] = target_slot
	
	# Обновляем оба инвентаря
	inventory_updated.emit()
	target_inventory.inventory_updated.emit()