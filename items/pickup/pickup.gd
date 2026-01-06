extends Area2D

# Сюда мы будем кидать ресурс предмета (Генератор, Аптечка и т.д.)
@export var item_data: ItemData

@onready var sprite = $Sprite

func _ready():
	if item_data != null:
		# Ставим картинку из ресурса
		sprite.texture = item_data.icon
	else:
		print("Внимание: Pickup без ItemData!")
		queue_free() # Удаляем, если забыли назначить предмет

func disable_pickup_temporarily(duration: float = 1.0):
	# Отключаем мониторинг (предмет перестает видеть игрока)
	# Используем set_deferred, так как это физическое свойство
	set_deferred("monitoring", false)
	
	# Ждем указанное время
	await get_tree().create_timer(duration).timeout
	
	# Включаем обратно. Если игрок все еще стоит на предмете, 
	# сигнал body_entered сработает сразу после этого.
	set_deferred("monitoring", true)

func _on_body_entered(body):
	# Проверяем, что это игрок
	if body.name == "Player":
		# Пытаемся найти у него инвентарь
		var inventory = body.get_node_or_null("Inventory")
		
		if inventory:
			# Пробуем добавить. Если получилось (вернуло true) — удаляемся.
			if inventory.add_item(item_data):
				print("Подобран предмет: ", item_data.name)
				queue_free()
			else:
				print("Инвентарь полон!")
