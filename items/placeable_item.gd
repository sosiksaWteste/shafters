extends ItemData
class_name PlaceableItem

# Сюда мы будем перетаскивать сцену (tscn) генератора или лампы
@export var placeable_scene: PackedScene

func use(target: Node) -> void:
	# Логику переключения в режим стройки добавим позже
	print("Выбран предмет для стройки: ", name)