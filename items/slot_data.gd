extends Resource
class_name SlotData

@export var item_data: ItemData
@export var quantity: int = 1: set = set_quantity

func set_quantity(value: int):
	quantity = value
	# Мы УБРАЛИ проверку "if quantity < 1: quantity = 1"
	# Теперь число может стать 0, и инвентарь сможет удалить этот слот.

# Проверка: можем ли мы добавить еще предметы в этот стек?
func can_merge_with(other_item: ItemData) -> bool:
	return item_data == other_item and item_data.stackable and quantity < item_data.max_stack_size

# Объединение стеков
func merge_with(other_item: ItemData, amount: int) -> int:
	var remaining_space = item_data.max_stack_size - quantity
	var amount_to_add = min(amount, remaining_space)
	
	quantity += amount_to_add
	return amount - amount_to_add