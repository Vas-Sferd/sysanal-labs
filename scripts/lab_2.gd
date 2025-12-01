# Main.gd
# Attached to the root Control node named "Main".

extends Control

@onready var incidence_set: IncidenceSet = $VBoxContainer/HBoxContainer/IncidencePanel/IncidenceSet
@onready var adjacency_table: MatrixTable = $VBoxContainer/HBoxContainer/AdjacencyPanel/AdjacencyTable
@onready var add_vertex_button: Button = $VBoxContainer/ControlButtons/AddVertexButton
@onready var remove_vertex_button: Button = $VBoxContainer/ControlButtons/RemoveVertexButton
@onready var convert_button: Button = $VBoxContainer/ControlButtons/ConvertButton
@onready var lock_edit_checkbox: CheckBox = $VBoxContainer/ControlButtons/LockEditCheckbox
@onready var outgoing_checkbox: CheckBox = $VBoxContainer/ControlButtons/OutgoingCheckbox
@onready var renumber_button: Button = $VBoxContainer/ControlButtons/RenumberButton
@onready var output_text: TextEdit = $VBoxContainer/OutputText

func _ready() -> void:
	add_vertex_button.pressed.connect(_on_add_vertex_pressed)
	remove_vertex_button.pressed.connect(_on_remove_vertex_pressed)
	convert_button.pressed.connect(_on_convert_pressed)
	lock_edit_checkbox.toggled.connect(_on_lock_edit_toggled)
	outgoing_checkbox.toggled.connect(_on_outgoing_toggled)
	renumber_button.pressed.connect(_on_renumber_pressed)
	outgoing_checkbox.button_pressed = true  # Initial outgoing

func _on_add_vertex_pressed() -> void:
	incidence_set.add_vertex()

func _on_remove_vertex_pressed() -> void:
	incidence_set.remove_vertex()

func _on_lock_edit_toggled(button_pressed: bool) -> void:
	incidence_set.set_locked(button_pressed)

func _on_outgoing_toggled(button_pressed: bool) -> void:
	incidence_set.set_is_outgoing(button_pressed)

func _on_convert_pressed() -> void:
	var num: int = incidence_set.num_vertices
	if num == 0:
		return
	var adjacency: Array[Array] = []
	for i: int in range(num):
		var adj_row: Array[int] = []
		for j: int in range(num):
			adj_row.append(0)
		adjacency.append(adj_row)
	for i: int in range(num):
		for neigh: int in incidence_set.out_neighbors[i]:
			adjacency[i][neigh] = 1
	adjacency_table.set_data(adjacency)

func _on_renumber_pressed() -> void:
	var num: int = incidence_set.num_vertices
	if num == 0:
		output_text.text = ""
		return
	var out_neighbors: Array[Array] = incidence_set.out_neighbors.duplicate(true)
	var in_neighbors: Array[Array] = []
	in_neighbors.resize(num)
	for i: int in range(num):
		in_neighbors[i] = []
	for u: int in range(num):
		for v: int in out_neighbors[u]:
			in_neighbors[v].append(u)
	var indegrees: Array[int] = []
	indegrees.resize(num)
	for i: int in range(num):
		indegrees[i] = in_neighbors[i].size()
	var queue: Array[int] = []
	for i: int in range(num):
		if indegrees[i] == 0:
			queue.append(i)
	var processed: int = 0
	var topo_order: Array[int] = []
	while not queue.is_empty():
		var u: int = queue.pop_front()
		topo_order.append(u)
		processed += 1
		for v: int in out_neighbors[u]:
			indegrees[v] -= 1
			if indegrees[v] == 0:
				queue.append(v)
	if processed < num:
		output_text.text = "Ошибка: граф содержит контуры, невозможно вычислить уровни"
		return
	var levels: Array[int] = []
	levels.resize(num)
	levels.fill(0)
	for u: int in topo_order:
		for v: int in out_neighbors[u]:
			levels[v] = max(levels[v], levels[u] + 1)
	var sorted_vertices: Array[int]
	sorted_vertices.assign(range(num))
	sorted_vertices.sort_custom(func(a: int, b: int) -> bool: return levels[a] < levels[b])
	var new_num: Array[int] = []
	new_num.resize(num)
	for i: int in range(num):
		new_num[sorted_vertices[i]] = i  # 0-based new numbers
	var new_out_neighbors: Array[Array] = []
	new_out_neighbors.resize(num)
	for i: int in range(num):
		new_out_neighbors[i] = []
	for old_u: int in range(num):
		var new_u: int = new_num[old_u]
		for old_v: int in out_neighbors[old_u]:
			var new_v: int = new_num[old_v]
			new_out_neighbors[new_u].append(new_v)
		new_out_neighbors[new_u].sort()
	var text: String = ""
	for old: int in range(num):
		text += "Старая вершина: " + str(old + 1) + ", Новая: " + str(new_num[old] + 1) + ", Уровень: " + str(levels[old]) + "\n"
	text += "\nНовый граф в формате множества правых инциденций:\n"
	for new_u: int in range(num):
		var neigh_str: PackedStringArray = []
		for v: int in new_out_neighbors[new_u]:
			neigh_str.append(str(v + 1))
		text += "G+(" + str(new_u + 1) + ") = {" + ", ".join(neigh_str) + "}\n"
	output_text.text = text

# Scene structure updates:
# 1. Root: Control "Main" (attach Main.gd).
# 2. VBoxContainer "VBoxContainer".
#    - HBoxContainer "ControlButtons".
#      - Button "AddVertexButton" text="Add Vertex".
#      - Button "RemoveVertexButton" text="Remove Vertex".
#      - Button "ConvertButton" text="Convert to Adjacency".
#      - CheckBox "LockEditCheckbox" text="Lock Editing".
#      - CheckBox "OutgoingCheckbox" text="Show Outgoing (G+)".
#      - Button "RenumberButton" text="Перенумеровать".
#    - HBoxContainer "HBoxContainer".
#      - Panel "IncidencePanel".
#        - VBoxContainer "IncidenceSet" (attach IncidenceSet.gd, initial_vertices=3).
#      - Panel "AdjacencyPanel".
#        - GridContainer "AdjacencyTable" (attach MatrixTable.gd, editable=false, has_column_headers=false, initial_rows=0, initial_columns=0).
#    - TextEdit "OutputText" (for displaying renumbering info, set to read-only if desired).
#
# Notes:
# - Added RenumberButton and OutputText to the scene.
# - Uses Kahn's algorithm for cycle detection and topological order.
# - Computes levels using dynamic programming in topological order.
# - Renumbers by sorting vertices by levels (stable sort by index if levels equal, since range is ordered).
# - Outputs info and new graph representation in text format.
# - Assumes 1-based numbering for display.
# - duplicate(true) for deep copy of out_neighbors.
