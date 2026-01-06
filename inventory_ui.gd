extends Control

# Ссылка на префаб слота, который мы создали
var slot_scene = preload("res://ui/Slot.tscn")

@onready var hotbar_container = $HotbarContainer
@onready var main_panel = $MainInventoryPanel
@onready var main_grid = $MainInventoryPanel/GridContainer
@onready var external_panel = $ExternalInventoryPanel
@onready var external_grid = $ExternalInventoryPanel/ExternalGrid

var inventory_ref: Inventory = null
var external_inventory_ref: Inventory = null

signal item_triggered(slot_data: SlotData, index: int)
signal item_dropped(index: int)

func _ready():
	main_panel.visible = false
	external_panel.visible = false

# Эту функцию мы вызовем из игрока, чтобы "подключить" UI к данным
func set_inventory(inventory: Inventory):
	inventory_ref = inventory
	# Подписываемся на сигнал обновления
	inventory_ref.inventory_updated.connect(update_ui)
	# Первичное обновление
	update_ui()

func _input(event):
	if event.is_action_pressed("inventory_toggle"):
		# Проверяем: если открыт основной инвентарь ИЛИ открыт сундук
		if main_panel.visible or external_panel.visible:
			# Закрываем всё разом
			close_external_inventory()
		else:
			# Если всё закрыто — открываем только инвентарь игрока
			main_panel.visible = true
			update_ui()

func update_ui():
	if inventory_ref == null:
		return

	# 1. Обновляем Хотбар (первые 4 слота)
	_clear_container(hotbar_container)
	for i in range(4): # Слоты 0-3
		var slot_data = inventory_ref.get_slot_data(i)
		_create_slot(hotbar_container, i, slot_data, inventory_ref)

	# 2. Обновляем Полную сетку (если она видима)
	# Мы отрисуем ВСЕ слоты (включая первые 4), как ты просил
	if main_panel.visible:
		_clear_container(main_grid)
		for i in range(inventory_ref.capacity):
			var slot_data = inventory_ref.get_slot_data(i)
			_create_slot(main_grid, i, slot_data, inventory_ref)

	if external_panel.visible and external_inventory_ref != null:
		_clear_container(external_grid)
		for i in range(external_inventory_ref.capacity):
			var slot_data = external_inventory_ref.get_slot_data(i)
			var slot = _create_slot(external_grid, i, slot_data, external_inventory_ref)
			# Важно: сообщаем слоту, что он принадлежит внешнему инвентарю
			slot.set_slot_data(external_inventory_ref, i, slot_data)

func _create_slot(container: Node, index: int, slot_data: SlotData, owner_inventory: Inventory) -> Button:
	var slot = slot_scene.instantiate()
	container.add_child(slot)
	
	# Используем переданный owner_inventory
	slot.set_slot_data(owner_inventory, index, slot_data) 
	
	slot.pressed.connect(_on_slot_pressed.bind(index))
	slot.gui_input.connect(_on_slot_gui_input.bind(index))
	
	return slot

# Новая функция для ЛКМ (Использовать)
func _on_slot_pressed(index: int):
	var slot_data = inventory_ref.get_slot_data(index)
	if slot_data:
		item_triggered.emit(slot_data, index)

# Обновленная функция для ПКМ (Выбросить)
func _on_slot_gui_input(event: InputEvent, index: int):
	# Ловим ТОЛЬКО правую кнопку мыши
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var slot_data = inventory_ref.get_slot_data(index)
			if slot_data:
				item_dropped.emit(index)
				get_viewport().set_input_as_handled() # Блокируем, чтобы не шло дальше

func _clear_container(container: Node):
	for child in container.get_children():
		child.queue_free()

func _on_slot_clicked(index: int):
	# Проверяем, какой клик был СЕЙЧАС
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var item = inventory_ref.get_item(index)
		if item:
			item_triggered.emit(item, index)
			
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var item = inventory_ref.get_item(index)
		if item:
			item_dropped.emit(index)

func open_external_inventory(ext_inv: Inventory):
	external_inventory_ref = ext_inv
	# Подписываемся на изменения в сундуке, чтобы UI обновлялся
	if not external_inventory_ref.inventory_updated.is_connected(update_ui):
		external_inventory_ref.inventory_updated.connect(update_ui)
	
	main_panel.visible = true # Открываем и свой инвентарь тоже
	external_panel.visible = true
	update_ui()

# Закрытие
func close_external_inventory():
	if external_inventory_ref:
		if external_inventory_ref.inventory_updated.is_connected(update_ui):
			external_inventory_ref.inventory_updated.disconnect(update_ui)
		external_inventory_ref = null
	
	external_panel.visible = false
	main_panel.visible = false
