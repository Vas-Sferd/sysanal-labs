# Main.gd
# Attached to the root Control node named "Main".

extends Control

@onready var incidence_table: MatrixTable = $VBoxContainer/HBoxContainer/IncidencePanel/IncidenceTable
@onready var adjacency_table: MatrixTable = $VBoxContainer/HBoxContainer/AdjacencyPanel/AdjacencyTable
@onready var add_row_button: Button = $VBoxContainer/ControlButtons/AddRowButton
@onready var remove_row_button: Button = $VBoxContainer/ControlButtons/RemoveRowButton
@onready var add_column_button: Button = $VBoxContainer/ControlButtons/AddColumnButton
@onready var remove_column_button: Button = $VBoxContainer/ControlButtons/RemoveColumnButton
@onready var convert_button: Button = $VBoxContainer/ControlButtons/ConvertButton
@onready var lock_edit_checkbox: CheckBox = $VBoxContainer/ControlButtons/LockEditCheckbox

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
	var incidence: Array = incidence_table.get_data()
	var num_vertices: int = incidence.size()
	if num_vertices == 0:
		return
	
	# Compute adjacency matrix (undirected graph, no loops/multiedges)
	var adjacency: Array = []
	for i: int in range(num_vertices):
		var adj_row: Array[int] = []
		for j: int in range(num_vertices):
			var sum_val: int = 0
			for k: int in range(incidence[0].size() if incidence.size() > 0 else 0):
				sum_val += incidence[i][k] * incidence[j][k]
			if i == j:
				adj_row.append(0)
			else:
				adj_row.append(1 if sum_val > 0 else 0)
		adjacency.append(adj_row)
	
	adjacency_table.set_data(adjacency)

# Scene structure updates:
# 1. Root: Control "Main" (attach Main.gd).
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
#      - Panel "AdjacencyPanel".
#        - GridContainer "AdjacencyTable" (attach MatrixTable.gd, set editable=false, has_column_headers=false, initial_rows=0, initial_columns=0).
#
# Notes:
# - Incidence table starts with 3 rows (vertices) and 2 columns (edges).
# - Adjacency table auto-resizes on conversion based on number of vertices.
# - Removal only if rows/columns > 0, and not if locked for editable tables.
# - Static typing used throughout.
# - @onready for node references.
