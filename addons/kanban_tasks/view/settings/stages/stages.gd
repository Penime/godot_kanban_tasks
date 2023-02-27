@tool
extends VBoxContainer


const __BoardData = preload("res://addons/kanban_tasks/data/board.gd")
const __StageData = preload("res://addons/kanban_tasks/data/stage.gd")

var board_data: __BoardData

var stylebox_n: StyleBoxFlat
var stylebox_hp: StyleBoxFlat

@onready var column_holder: HBoxContainer = %ColumnHolder
@onready var column_add: Button = %AddColumn
@onready var warning_sign: Button = %WarningSign
@onready var warn_about_empty_deletion = %WarnAboutEmptyDeletion


func _ready():
	column_add.focus_mode = Control.FOCUS_NONE
	column_add.pressed.connect(__on_add_stage.bind(-1))

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column_add.add_child(center_container)

	var plus := TextureRect.new()
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_container.add_child(plus)

	notification(NOTIFICATION_THEME_CHANGED)


func _notification(what) -> void:
	match(what):
		NOTIFICATION_THEME_CHANGED:
			stylebox_n = get_theme_stylebox(&"normal", &"Button").duplicate()
			stylebox_n.set_border_width_all(1)
			stylebox_n.border_color = Color8(32, 32, 32, 255)

			stylebox_hp = get_theme_stylebox(&"read_only", &"LineEdit").duplicate()
			stylebox_hp.set_border_width_all(1)
			stylebox_hp.border_color = Color8(32, 32, 32, 128)

			if is_instance_valid(column_add):
				column_add.get_child(0).get_child(0).texture = get_theme_icon(&"Add", &"EditorIcons")
				column_add.add_theme_stylebox_override(&"normal", stylebox_n)
				column_add.add_theme_stylebox_override(&"hover", stylebox_hp)
				column_add.add_theme_stylebox_override(&"pressed", stylebox_hp)
			if is_instance_valid(warning_sign):
				warning_sign.icon = get_theme_icon(&"NodeWarning", &"EditorIcons")


func update():
	if not board_data.layout.changed.is_connected(update):
		board_data.layout.changed.connect(update)

	var too_high = false
	for column in board_data.layout.columns:
		if len(column) > 3:
			too_high = true
	warning_sign.visible = too_high or len(board_data.layout.columns) > 4

	for child in column_holder.get_children():
		child.queue_free()

	var index = 0
	for column in board_data.layout.columns:
		var column_entry := VBoxContainer.new()
		column_entry.add_theme_constant_override(&"separation", 5)
		column_holder.add_child(column_entry)

		for stage in column:
			var stage_entry := Button.new()
			stage_entry.tooltip_text = board_data.get_stage(stage).title
			stage_entry.focus_mode = Control.FOCUS_NONE
			stage_entry.set_v_size_flags(SIZE_EXPAND_FILL)
			stage_entry.custom_minimum_size = Vector2i(70, 50)
			stage_entry.add_theme_stylebox_override(&"normal", stylebox_n)
			stage_entry.add_theme_stylebox_override(&"hover", stylebox_hp)
			stage_entry.add_theme_stylebox_override(&"pressed", stylebox_hp)
			stage_entry.add_theme_stylebox_override(&"disabled", stylebox_hp)
			stage_entry.pressed.connect(__on_remove_stage.bind(stage))
			stage_entry.disabled = len(board_data.layout.columns) <= 1 and len(board_data.layout.columns[0]) <= 1
			column_entry.add_child(stage_entry)

			var center_container := CenterContainer.new()
			center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
			center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stage_entry.add_child(center_container)

			var remove := TextureRect.new()
			remove.mouse_filter = Control.MOUSE_FILTER_IGNORE
			remove.texture = get_theme_icon(&"Remove", &"EditorIcons")
			center_container.add_child(remove)

		var add = Button.new()
		add.custom_minimum_size = Vector2i(70, 40)
		add.focus_mode = Control.FOCUS_NONE
		add.pressed.connect(__on_add_stage.bind(index))
		add.add_theme_stylebox_override(&"normal", stylebox_n)
		add.add_theme_stylebox_override(&"hover", stylebox_hp)
		add.add_theme_stylebox_override(&"pressed", stylebox_hp)
		column_entry.add_child(add)

		var center_container = CenterContainer.new()
		center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add.add_child(center_container)

		var plus := TextureRect.new()
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center_container.add_child(plus)
		plus.texture = get_theme_icon(&"Add", &"EditorIcons")

		index += 1


func __on_add_stage(column: int) -> void:
	var data = __StageData.new("New Stage")
	var uuid = board_data.add_stage(data)

	var columns = board_data.layout.columns
	if column < len(board_data.layout.columns) and column >= 0:
		columns[column].append(uuid)
	else:
		columns.append(PackedStringArray([uuid]))
	board_data.layout.columns = columns


func __on_remove_stage(uuid: String) -> void:
	if len(board_data.get_stage(uuid).tasks) == 0:
		pass
	else:
		pass

	board_data.remove_stage(uuid)

	var columns = board_data.layout.columns
	for column in columns.duplicate():
		if uuid in column:
			column.remove_at(column.find(uuid))
		if len(column) == 0:
			columns.erase(column)

	board_data.layout.columns = columns

