# Main.gd
# Attached to the root Control node named "Main".

extends Control

@onready var incidence_set: IncidenceSet = $VBoxContainer/HBoxContainer/IncidencePanel2/IncidenceSet
@onready var incidence_table: MatrixTable = $VBoxContainer/HBoxContainer/IncidencePanel/IncidenceTable
@onready var adjacency_table: MatrixTable = $VBoxContainer/HBoxContainer/AdjacencyPanel/AdjacencyTable
@onready var add_row_button: Button = $VBoxContainer/ControlButtons/AddRowButton
@onready var remove_row_button: Button = $VBoxContainer/ControlButtons/RemoveRowButton
@onready var add_column_button: Button = $VBoxContainer/ControlButtons/AddColumnButton
@onready var remove_column_button: Button = $VBoxContainer/ControlButtons/RemoveColumnButton
@onready var convert_button: Button = $VBoxContainer/ControlButtons/ConvertButton
@onready var lock_edit_checkbox: CheckBox = $VBoxContainer/ControlButtons/LockEditCheckbox
@onready var error_dialog: AcceptDialog = $ErrorDialog

func _ready() -> void:
	add_row_button.pressed.connect(_on_add_row_pressed)
	remove_row_button.pressed.connect(_on_remove_row_pressed)
	add_column_button.pressed.connect(_on_add_column_pressed)
	remove_column_button.pressed.connect(_on_remove_column_pressed)
	convert_button.pressed.connect(_on_convert_pressed)
	lock_edit_checkbox.toggled.connect(_on_lock_edit_toggled)

func _on_add_row_pressed() -> void:
	incidence_table.add_row()

func _on_remove_row_pressed() -> void:
	incidence_table.remove_row()

func _on_add_column_pressed() -> void:
	incidence_table.add_column()

func _on_remove_column_pressed() -> void:
	incidence_table.remove_column()

func _on_lock_edit_toggled(button_pressed: bool) -> void:
	incidence_table.set_locked(button_pressed)

func _on_convert_pressed() -> void:
	var incidence: Array[Array] = incidence_table.get_data()
	var num_vertices: int = incidence.size()
	if num_vertices == 0:
		return
	var num_edges: int = incidence[0].size() if incidence.size() > 0 and incidence[0].size() > 0 else 0
	
	# Validate each column
	for col: int in range(num_edges):
		var column_values: Array[int] = []
		for row: int in range(num_vertices):
			column_values.append(incidence[row][col])
		var count_minus: int = column_values.count(-1)
		var count_plus: int = column_values.count(1)
		var count_zero: int = column_values.count(0)
		if not ((count_minus == 1 and count_plus == 1 and count_zero == num_vertices - 2) or (count_minus == 0 and count_plus == 0 and count_zero == num_vertices)):
			error_dialog.dialog_text = "Ошибка: столбец " + str(col + 1) + " не содержит ровно одну -1 и одну 1 (или все 0)."
			error_dialog.popup_centered()
			return
	
	# Compute adjacency matrix for directed graph
	var adjacency: Array[Array] = []
	for i: int in range(num_vertices):
		var adj_row: Array[int] = []
		for j: int in range(num_vertices):
			adj_row.append(0)
		adjacency.append(adj_row)
	
	for col: int in range(num_edges):
		var from_vertex: int = -1
		var to_vertex: int = -1
		for row: int in range(num_vertices):
			var val: int = incidence[row][col]
			if val == -1:
				from_vertex = row
			elif val == 1:
				to_vertex = row
		if from_vertex != -1 and to_vertex != -1:
			adjacency[from_vertex][to_vertex] = 1
	
	adjacency_table.set_data(adjacency)
	
	# Update IncidenceSet with out_neighbors
	incidence_set.out_neighbors.clear()
	for i: int in range(num_vertices):
		var neighbors: Array[int] = []
		for j: int in range(num_vertices):
			if adjacency[i][j] == 1:
				neighbors.append(j)
		incidence_set.out_neighbors.append(neighbors)
	
	# Rebuild IncidenceSet rows if necessary
	if incidence_set.num_vertices != num_vertices:
		# Adjust vertices in IncidenceSet
		while incidence_set.num_vertices > num_vertices:
			incidence_set.remove_vertex()
		while incidence_set.num_vertices < num_vertices:
			incidence_set.add_vertex()
	
	# Rebuild all rows
	for idx: int in range(num_vertices):
		incidence_set._rebuild_row(idx)
	incidence_set.set_is_outgoing(true)

# Scene structure updates:
# 1. Root: Control "Main" (attach Main.gd).
#    - Add AcceptDialog named "ErrorDialog" (for error messages).
# 2. VBoxContainer "VBoxContainer".
#    - HBoxContainer "ControlButtons".
#      - Button "AddRowButton" text="Add Row".
#      - Button "RemoveRowButton" text="Remove Row".
#      - Button "AddColumnButton" text="Add Column".
#      - Button "RemoveColumnButton" text="Remove Column".
#      - Button "ConvertButton" text="Convert to Adjacency".
#      - CheckBox "LockEditCheckbox" text="Lock Editing".
#    - HBoxContainer "HBoxContainer".
#      - Panel "IncidencePanel".
#        - GridContainer "IncidenceTable" (attach MatrixTable.gd, set editable=true, has_column_headers=true, column_header_prefix="Edge ", initial_rows=3, initial_columns=2).
#      - Panel "IncidencePanel2".
#        - VBoxContainer "IncidenceSet" (attach IncidenceSet.gd, initial_vertices=3).
#      - Panel "AdjacencyPanel".
#        - GridContainer "AdjacencyTable" (attach MatrixTable.gd, set editable=false, has_column_headers=false, initial_rows=0, initial_columns=0).
#
# Notes:
# - Updated MatrixTable to allow -1 in cells.
# - In _on_convert_pressed, validate columns for directed incidence (one -1, one 1 per edge column, or all 0).
# - Compute directed adjacency from incidence.
# - Update IncidenceSet with computed out_neighbors and rebuild its display.
# - Assumes IncidenceSet.gd has the necessary methods from previous versions (add_vertex, remove_vertex, _rebuild_row, etc.).
# - Uses AcceptDialog for errors; add it to the scene root.
