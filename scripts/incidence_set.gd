# IncidenceSet.gd
# Attached to VBoxContainer nodes for incidence sets (adjacency lists for directed graph).

class_name IncidenceSet
extends VBoxContainer

@export var editable: bool = true
@export var locked: bool = false
@export var initial_vertices: int = 3

var num_vertices: int = 0
var vertex_rows: Array[HBoxContainer] = []

func _ready() -> void:
	resize(initial_vertices)

func create_edit(text: String) -> Control:
	if editable:
		var le: LineEdit = LineEdit.new()
		le.text = text
		le.editable = not locked
		le.placeholder_text = "e.g., 2∨ 3∨ 5∨ (outgoing vertices, 1-based)"
		le.text_changed.connect(_on_text_changed.bind(le))
		return le
	else:
		var lb: Label = Label.new()
		lb.text = text
		return lb

func _on_text_changed(new_text: String, le: LineEdit) -> void:
	# Basic validation: allow only digits, commas, spaces, ∨
	var valid_chars: String = "0123456789, ∨"
	for ch: String in new_text:
		if not valid_chars.contains(ch):
			le.text = new_text.replace(ch, "")
			le.caret_column = len(le.text)
			return

func set_locked(value: bool) -> void:
	locked = value
	if editable:
		for row: HBoxContainer in vertex_rows:
			var edit: Control = row.get_child(1)
			if edit is LineEdit:
				edit.editable = not locked

func add_vertex() -> void:
	if editable and locked:
		return
	resize(num_vertices + 1)

func remove_vertex() -> void:
	if num_vertices <= 0 or (editable and locked):
		return
	resize(num_vertices - 1)

func resize(new_num: int) -> void:
	while vertex_rows.size() > new_num:
		var last_row: HBoxContainer = vertex_rows.pop_back()
		last_row.queue_free()
	
	while vertex_rows.size() < new_num:
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		var vertex_id: int = vertex_rows.size() + 1
		label.text = "+ | G+(" + str(vertex_id) + ")= "
		row.add_child(label)
		var edit: Control = create_edit("")
		row.add_child(edit)
		add_child(row)
		vertex_rows.append(row)
	
	num_vertices = new_num

func get_data() -> Array[Array]:
	var adj: Array[Array] = []
	for i: int in range(num_vertices):
		var tmp = []
		for j: int in range(num_vertices):
			tmp.append(0)
		adj.append(tmp)  # Array of 0s
	
	for r: int in range(num_vertices):
		var row: HBoxContainer = vertex_rows[r]
		var edit: Control = row.get_child(1)
		var text: String = edit.text
		var targets: PackedStringArray
		
		var has_separator: bool = text.contains("∨") or text.contains(",")
		if not has_separator:
			targets = text.split(" ", false)
		else:
			var text_norm: String = text.replace(" ", "")
			text_norm = text_norm.replace(",", "∨")
			targets = text_norm.split("∨", false)
		
		for t_str: String in targets:
			t_str = t_str.strip_edges()
			if t_str.is_valid_int():
				var t: int = int(t_str) - 1  # 1-based to 0-based
				if t >= 0 and t < num_vertices and t != r:  # Assume no self-loops
					adj[r][t] = 1
	
	return adj

func set_data(data: Array[Array]) -> void:
	if data.is_empty():
		return
	var data_vertices: int = data.size()
	resize(data_vertices)
	for r: int in range(data_vertices):
		var targets: Array[String] = []
		for c: int in range(data_vertices):
			if data[r][c] == 1:
				targets.append(str(c + 1) + "∨")
		var row: HBoxContainer = vertex_rows[r]
		var edit: Control = row.get_child(1)
		edit.text = " ".join(targets)
