# IncidenceSet.gd
# Attached to VBoxContainer node for incidence sets.

class_name IncidenceSet
extends VBoxContainer

@export var initial_vertices: int = 3
@export var locked: bool = false

var num_vertices: int = 0
var is_outgoing: bool = true
var out_neighbors: Array[Array] = []
var rows: Array[HBoxContainer] = []

func _ready() -> void:
	num_vertices = initial_vertices
	for i: int in range(num_vertices):
		out_neighbors.append([])
		_add_row(i)
	_update_lock_state()

func set_locked(value: bool) -> void:
	locked = value
	_update_lock_state()

func _update_lock_state() -> void:
	for row: HBoxContainer in rows:
		row.get_child(0).disabled = locked  # +
		row.get_child(1).disabled = locked  # -
		var container: HBoxContainer = row.get_node("ComboContainer")
		for ob: OptionButton in container.get_children():
			ob.disabled = locked

func set_is_outgoing(value: bool) -> void:
	if value != is_outgoing:
		is_outgoing = value
		for i: int in range(num_vertices):
			_update_label(rows[i].get_node("Label"), i)
			_rebuild_row(i)

func add_vertex() -> void:
	if locked:
		return
	num_vertices += 1
	out_neighbors.append([])
	_add_row(num_vertices - 1)
	_update_all_items()

func remove_vertex() -> void:
	if num_vertices <= 0 or locked:
		return
	var deleted: int = num_vertices - 1
	for u: int in range(num_vertices):
		out_neighbors[u] = out_neighbors[u].filter(func(n: int) -> bool: return n != deleted)
	out_neighbors.pop_back()
	rows.back().queue_free()
	rows.pop_back()
	num_vertices -= 1
	_update_all_items()

func _add_row(idx: int) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	var plus: Button = Button.new()
	plus.text = "+"
	plus.pressed.connect(_on_plus_pressed.bind(idx))
	hbox.add_child(plus)
	var minus: Button = Button.new()
	minus.text = "-"
	minus.pressed.connect(_on_minus_pressed.bind(idx))
	hbox.add_child(minus)
	var label: Label = Label.new()
	label.name = "Label"
	_update_label(label, idx)
	hbox.add_child(label)
	var eq: Label = Label.new()
	eq.text = "="
	hbox.add_child(eq)
	var combo_container: HBoxContainer = HBoxContainer.new()
	combo_container.name = "ComboContainer"
	hbox.add_child(combo_container)
	add_child(hbox)
	rows.append(hbox)

func _update_label(label: Label, idx: int) -> void:
	var prefix: String = "G+" if is_outgoing else "G-"
	label.text = prefix + "(" + str(idx + 1) + ")"

func _rebuild_row(idx: int) -> void:
	var container: HBoxContainer = rows[idx].get_node("ComboContainer")
	for child: Node in container.get_children():
		child.queue_free()
	var neighbors: Array[int] = []
	if is_outgoing:
		neighbors.assign(out_neighbors[idx])
	else:
		for u: int in range(num_vertices):
			if idx in out_neighbors[u]:
				neighbors.append(u)
	neighbors.sort()
	for neigh: int in neighbors:
		var ob: OptionButton = _create_option_button(idx, neigh)
		container.add_child(ob)

func _create_option_button(vertex: int, selected_val: int) -> OptionButton:
	var ob: OptionButton = OptionButton.new()
	ob.disabled = locked
	_update_items(ob, vertex)
	var sel_index: int = -1
	for ii: int in range(ob.item_count):
		if int(ob.get_item_text(ii)) == selected_val + 1:
			sel_index = ii
			break
	ob.selected = sel_index
	ob.set_meta("last_valid", sel_index)
	ob.item_selected.connect(_on_item_selected.bind(vertex, ob))
	return ob

func _update_items(ob: OptionButton, vertex: int) -> void:
	ob.clear()
	for j: int in range(1, num_vertices + 1):
		if j != vertex + 1:
			ob.add_item(str(j))

func _on_plus_pressed(vertex: int) -> void:
	var container: HBoxContainer = rows[vertex].get_node("ComboContainer")
	var ob: OptionButton = OptionButton.new()
	ob.disabled = locked
	_update_items(ob, vertex)
	ob.selected = -1
	ob.set_meta("last_valid", -1)
	ob.item_selected.connect(_on_item_selected.bind(vertex, ob))
	container.add_child(ob)

func _on_minus_pressed(vertex: int) -> void:
	var container: HBoxContainer = rows[vertex].get_node("ComboContainer")
	if container.get_child_count() > 0:
		var last: OptionButton = container.get_child(-1) as OptionButton
		if last.selected >= 0:
			var val: int = int(last.get_item_text(last.selected)) - 1
			if is_outgoing:
				out_neighbors[vertex].erase(val)
			else:
				out_neighbors[val].erase(vertex)
		last.queue_free()

func _on_item_selected(index: int, vertex: int, ob: OptionButton) -> void:
	var new_val: int = int(ob.get_item_text(index)) - 1
	# Check for duplicates
	var val_counts: Dictionary = {}
	var container: HBoxContainer = rows[vertex].get_node("ComboContainer")
	for child: OptionButton in container.get_children():
		if child.selected >= 0:
			var v: int = int(child.get_item_text(child.selected))
			if not val_counts.has(v):
				val_counts[v] = 0
			val_counts[v] += 1
	var is_duplicate: bool = false
	for count: int in val_counts.values():
		if count > 1:
			is_duplicate = true
			break
	if is_duplicate:
		ob.selected = ob.get_meta("last_valid")
		return
	# Update data
	var old_index: int = ob.get_meta("last_valid")
	var from_v: int
	var to_v: int
	if old_index >= 0:
		var old_val: int = int(ob.get_item_text(old_index)) - 1
		if is_outgoing:
			from_v = vertex
			to_v = old_val
		else:
			from_v = old_val
			to_v = vertex
		out_neighbors[from_v].erase(to_v)
	if is_outgoing:
		from_v = vertex
		to_v = new_val
	else:
		from_v = new_val
		to_v = vertex
	out_neighbors[from_v].append(to_v)
	out_neighbors[from_v].sort()  # Optional, for consistency
	ob.set_meta("last_valid", index)

func _update_all_items() -> void:
	for i: int in range(num_vertices):
		var container: HBoxContainer = rows[i].get_node("ComboContainer")
		for ob: OptionButton in container.get_children():
			var prev_selected: int = ob.selected
			var prev_val: int = -1
			if prev_selected >= 0:
				prev_val = int(ob.get_item_text(prev_selected)) - 1
			_update_items(ob, i)
			var new_index: int = -1
			for k: int in range(ob.item_count):
				if int(ob.get_item_text(k)) == prev_val + 1:
					new_index = k
					break
			ob.selected = new_index
			ob.set_meta("last_valid", new_index)
			# If new_index == -1 and prev_val != -1, edge was to deleted vertex, already removed in remove_vertex
