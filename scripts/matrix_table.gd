# MatrixTable.gd
# Attached to GridContainer nodes for both incidence and adjacency matrices.

class_name MatrixTable
extends GridContainer

@export var editable: bool = true
@export var locked: bool = false
@export var has_column_headers: bool = false
@export var column_header_prefix: String = "Column "
@export var initial_rows: int = 0
@export var initial_columns: int = 0

var rows: int = 0
var _columns: int = 0
var headers: Array[Label] = []
var cells: Array[Array] = []

func _ready() -> void:
	rows = initial_rows
	_columns = initial_columns
	init_cells()
	
func init_cells() -> void:
	cells = []
	for r: int in range(rows):
		var row_arr: Array[Control] = []
		for c: int in range(_columns):
			row_arr.append(create_cell("0"))
		cells.append(row_arr)
	_rebuild_grid()

func create_cell(text: String) -> Control:
	if editable:
		var le: LineEdit = LineEdit.new()
		le.text = text
		le.editable = not locked
		le.text_changed.connect(_on_cell_text_changed.bind(le))
		return le
	else:
		var lb: Label = Label.new()
		lb.text = text
		return lb

func _on_cell_text_changed(new_text: String, le: LineEdit) -> void:
	if new_text not in ["0", "1", ""]:
		le.text = "0"
		le.caret_column = len(le.text)

func set_locked(value: bool) -> void:
	locked = value
	if editable:
		for row: Array[Control] in cells:
			for cell: Control in row:
				if cell is LineEdit:
					cell.editable = not locked

func add_row() -> void:
	if editable and locked:
		return  # Cannot add if locked
	var new_row: Array[Control] = []
	for c: int in range(_columns):
		new_row.append(create_cell("0"))
	cells.append(new_row)
	rows += 1
	_rebuild_grid()

func remove_row() -> void:
	if rows <= 0 or (editable and locked):
		return
	cells.pop_back()
	rows -= 1
	_rebuild_grid()

func add_column() -> void:
	if editable and locked:
		return
	for row: Array[Control] in cells:
		row.append(create_cell("0"))
	_columns += 1
	_rebuild_grid()

func remove_column() -> void:
	if _columns <= 0 or (editable and locked):
		return
	for row: Array[Control] in cells:
		row.pop_back()
	_columns -= 1
	_rebuild_grid()

func _rebuild_grid() -> void:
	for child: Node in get_children():
		remove_child(child)  # Reuse nodes later
	
	headers = []
	if has_column_headers:
		for c: int in range(_columns):
			var label: Label = Label.new()
			label.text = column_header_prefix + str(c + 1)
			add_child(label)
			headers.append(label)
	
	for r: int in range(rows):
		for c: int in range(_columns):
			add_child(cells[r][c])
	
	self._columns = _columns  # Set GridContainer _columns

func get_data() -> Array[Array]:
	var data: Array[Array] = []
	for row: Array[Control] in cells:
		var row_data: Array[int] = []
		for cell: Control in row:
			row_data.append(int(cell.text))
		data.append(row_data)
	return data

func set_data(data: Array[Array]) -> void:
	if data.is_empty():
		return
	var data_rows: int = data.size()
	var data_cols: int = data[0].size()
	resize(data_rows, data_cols)
	for r: int in range(data_rows):
		for c: int in range(data_cols):
			cells[r][c].text = str(data[r][c])

func resize(new_rows: int, new_columns: int) -> void:
	# For output tables, reset cells to new size with defaults
	cells = []
	rows = new_rows
	_columns = new_columns
	for r: int in range(rows):
		var row_arr: Array[Control] = []
		for c: int in range(_columns):
			row_arr.append(create_cell("0"))
		cells.append(row_arr)
	_rebuild_grid()
