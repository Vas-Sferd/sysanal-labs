# Main.gd
# Attached to the root Control node named "Main".

extends Control

@onready var incidence_set: IncidenceSet = $VBoxContainer/HBoxContainer/IncidencePanel/IncidenceSet
@onready var adjacency_table: MatrixTable = $VBoxContainer/HBoxContainer/AdjacencyPanel/AdjacencyTable
@onready var add_vertex_button: Button = $VBoxContainer/ControlButtons/AddVertexButton
@onready var remove_vertex_button: Button = $VBoxContainer/ControlButtons/RemoveVertexButton
@onready var convert_button: Button = $VBoxContainer/ControlButtons/ConvertButton
@onready var lock_edit_checkbox: CheckBox = $VBoxContainer/ControlButtons/LockEditCheckbox
@onready var renumber_button: Button = $VBoxContainer/ControlButtons/RenumberButton
@onready var revert_button: Button = $VBoxContainer/ControlButtons/RevertButton
@onready var error_label: Label = $VBoxContainer/OutputPanel/OutputVBox/ErrorLabel
@onready var levels_grid: GridContainer = $VBoxContainer/OutputPanel/OutputVBox/LevelsGrid
@onready var renumbered_set: IncidenceSet = $VBoxContainer/OutputPanel/OutputVBox/RenumberedSet

func _ready() -> void:
	add_vertex_button.pressed.connect(_on_add_vertex_pressed)
	remove_vertex_button.pressed.connect(_on_remove_vertex_pressed)
	convert_button.pressed.connect(_on_convert_pressed)
	lock_edit_checkbox.toggled.connect(_on_lock_edit_toggled)
	renumber_button.pressed.connect(_on_renumber_pressed)
	revert_button.pressed.connect(_on_revert_pressed)
	_clear_output()

func _on_add_vertex_pressed() -> void:
	incidence_set.add_vertex()

func _on_remove_vertex_pressed() -> void:
	incidence_set.remove_vertex()

func _on_lock_edit_toggled(button_pressed: bool) -> void:
	incidence_set.set_locked(button_pressed)
	add_vertex_button.disabled = button_pressed
	remove_vertex_button.disabled = button_pressed

func _on_convert_pressed() -> void:
	var adjacency: Array[Array] = incidence_set.get_data()
	adjacency_table.set_data(adjacency)

func _on_renumber_pressed() -> void:
	_clear_output()
	var adjacency: Array[Array] = incidence_set.get_data()
	var n: int = adjacency.size()
	if n == 0:
		error_label.text = "Ошибка: граф пустой"
		error_label.visible = true
		return

	# Compute indegrees
	var indegrees: Array[int] = []
	for i: int in range(n):
		indegrees.append(0)
	for i: int in range(n):
		for j: int in range(n):
			if adjacency[i][j] == 1:
				indegrees[j] += 1

	# Levels array
	var levels: Array[int] = []
	for i: int in range(n):
		levels.append(0)

	# Kahn's algorithm
	var queue: Array[int] = []
	for i: int in range(n):
		if indegrees[i] == 0:
			queue.append(i)
			levels[i] = 0

	var processed: int = 0
	while not queue.is_empty():
		var u: int = queue.pop_front()
		processed += 1
		for v: int in range(n):
			if adjacency[u][v] == 1:
				levels[v] = max(levels[v], levels[u] + 1)
				indegrees[v] -= 1
				if indegrees[v] == 0:
					queue.append(v)

	if processed != n:
		error_label.text = "Ошибка: граф содержит контуры, невозможно вычислить уровни"
		error_label.visible = true
		return

	# Sort vertices by level, then by old index if tie
	var vertex_list: Array[Dictionary] = []
	for i: int in range(n):
		vertex_list.append({"old": i, "level": levels[i]})
	vertex_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["level"] != b["level"]:
			return a["level"] < b["level"]
		return a["old"] < b["old"]
	)

	# Assign new numbers (0-based internally)
	var old_to_new: Array[int] = []
	for i: int in range(n):
		old_to_new.append(0)
	for idx: int in range(n):
		var old: int = vertex_list[idx]["old"]
		old_to_new[old] = idx

	# Fill levels grid: Headers + data
	levels_grid.columns = 3
	var headers: Array[String] = ["Старый номер", "Новый номер", "Уровень"]
	for h: String in headers:
		var lb: Label = Label.new()
		lb.text = h
		levels_grid.add_child(lb)

	for i: int in range(n):
		var old: int = i + 1  # 1-based
		var new_num: int = old_to_new[i] + 1
		var level: int = levels[i]
		var values: Array[String] = [str(old), str(new_num), str(level)]
		for v: String in values:
			var lb: Label = Label.new()
			lb.text = v
			levels_grid.add_child(lb)

	# New adjacency for renumbered
	var new_adj: Array[Array] = []
	for i: int in range(n):
		var row: Array[int] = []
		for j: int in range(n):
			row.append(0)
		new_adj.append(row)
	for old_u: int in range(n):
		for old_v: int in range(n):
			if adjacency[old_u][old_v] == 1:
				var new_u: int = old_to_new[old_u]
				var new_v: int = old_to_new[old_v]
				new_adj[new_u][new_v] = 1

	# Set to renumbered_set (editable=false)
	renumbered_set.set_data(new_adj)

	# Show output
	$VBoxContainer/OutputPanel.visible = true

func _on_revert_pressed() -> void:
	_clear_output()

func _clear_output() -> void:
	error_label.visible = false
	error_label.text = ""
	for child: Node in levels_grid.get_children():
		levels_grid.remove_child(child)
		child.queue_free()
	renumbered_set.set_data([])
	$VBoxContainer/OutputPanel.visible = false

# Scene structure updates:
# 1. Root: Control "Main" (attach Main.gd).
# 2. VBoxContainer "VBoxContainer".
#    - HBoxContainer "ControlButtons".
#      - Button "AddVertexButton" text="Add Vertex".
#      - Button "RemoveVertexButton" text="Remove Vertex".
#      - Button "ConvertButton" text="Convert to Adjacency Matrix".
#      - Button "RenumberButton" text="Renumber Hierarchically".
#      - Button "RevertButton" text="Revert".
#      - CheckBox "LockEditCheckbox" text="Lock Editing".
#    - HBoxContainer "HBoxContainer".
#      - Panel "IncidencePanel".
#        - VBoxContainer "IncidenceSet" (attach IncidenceSet.gd, editable=true, initial_vertices=5).
#      - Panel "AdjacencyPanel".
#        - GridContainer "AdjacencyTable" (attach MatrixTable.gd, editable=false, has_column_headers=false, initial_rows=0, initial_columns=0).
#    - Panel "OutputPanel" (initially visible=false).
#      - Label "ErrorLabel" (initially visible=false).
#      - VBoxContainer "OutputVBox".
#        - GridContainer "LevelsGrid" (columns=3).
#        - VBoxContainer "RenumberedSet" (attach IncidenceSet.gd, editable=false, initial_vertices=0).
#
# Notes:
# - Added RenumberButton and RevertButton.
# - OutputPanel for results: error, levels table (old/new/level, 1-based), renumbered incidence set (non-editable).
# - Revert clears and hides output.
# - Uses Kahn's algorithm for topo sort and level computation.
# - Detects cycles and shows error if present.
# - Renumbering: sort by level asc, then old index asc; new numbers 1-based.
# - Transforms to new incidence set with remapped numbers.
# - MatrixTable.gd and IncidenceSet.gd unchanged.
