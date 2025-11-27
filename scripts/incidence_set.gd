# IncidenceSet.gd
# Attached to VBoxContainer node for incidence sets.

class_name IncidenceSet
extends VBoxContainer

@export var is_out_mode: bool = true
@export var locked: bool = false
@export var initial_vertices: int = 3

var num_vertices: int = 0
var row_containers: Array[HBoxContainer] = []

func _ready() -> void:
	num_vertices = initial_vertices
	init_rows()

func init_rows() -> void:
	for i: int in range(num_vertices):
		add_row()

func create_option_button() -> OptionButton:
	var ob: OptionButton = OptionButton.new()
	populate_options(ob)
	ob.disabled = locked
	ob.item_selected.connect(_on_item_selected.bind(ob))
	return ob

func populate_options(ob: OptionButton) -> void:
	ob.clear()
	for k: int in range(1, num_vertices + 1):
		ob.add_item(str(k))

func _on_item_selected(index: int, ob: OptionButton) -> void:
	var row_index: int = row_containers.find(ob.get_parent().get_parent())  # HBox combos -> HBox row
	var self_vertex: int = row_index + 1
	var selected_vertex: int = index + 1 if index >= 0 else 0
	if selected_vertex == self_vertex:
		ob.select(-1)  # No loops allowed

func add_row() -> void:
	if locked:
		return
	# Update existing options first to include new vertex
	num_vertices += 1
	update_all_options(num_vertices)
	
	# Create new row
	var row_hbox: HBoxContainer = HBoxContainer.new()
	add_child(row_hbox)
	row_containers.append(row_hbox)
	
	var add_button: Button = Button.new()
	add_button.text = "+"
	add_button.disabled = locked
	add_button.pressed.connect(_on_add_combo_pressed.bind(row_hbox))
	row_hbox.add_child(add_button)
	
	var remove_button: Button = Button.new()
	remove_button.text = "-"
	remove_button.disabled = locked
	remove_button.pressed.connect(_on_remove_combo_pressed.bind(row_hbox))
	row_hbox.add_child(remove_button)
	
	var label: Label = Label.new()
	label.text = get_label_text(row_containers.size())
	row_hbox.add_child(label)
	
	var eq_label: Label = Label.new()
	eq_label.text = "="
	row_hbox.add_child(eq_label)
	
	var combos_container: HBoxContainer = HBoxContainer.new()
	row_hbox.add_child(combos_container)
	
	# Initially empty

func remove_row() -> void:
	if num_vertices <= 0 or locked:
		return
	# Remove last row
	var last_row: HBoxContainer = row_containers.pop_back()
	remove_child(last_row)
	last_row.queue_free()
	
	# Update options and remove invalid selections
	num_vertices -= 1
	update_all_options(num_vertices)

func update_all_options(new_n: int) -> void:
	for row: HBoxContainer in row_containers:
		var combos_container: HBoxContainer = row.get_child(4) as HBoxContainer  # Index 4: combos
		var to_remove: Array[OptionButton] = []
		for child: Node in combos_container.get_children():
			var ob: OptionButton = child as OptionButton
			var selected_val: int = int(ob.text) if ob.selected_index >= 0 else 0
			populate_options(ob)
			if selected_val > new_n:
				to_remove.append(ob)
			elif selected_val > 0:
				ob.select(selected_val - 1)
		for ob: OptionButton in to_remove:
			combos_container.remove_child(ob)
			ob.queue_free()

func _on_add_combo_pressed(row_hbox: HBoxContainer) -> void:
	if locked:
		return
	var combos_container: HBoxContainer = row_hbox.get_child(4) as HBoxContainer
	var ob: OptionButton = create_option_button()
	combos_container.add_child(ob)

func _on_remove_combo_pressed(row_hbox: HBoxContainer) -> void:
	if locked:
		return
	var combos_container: HBoxContainer = row_hbox.get_child(4) as HBoxContainer
	var child_count: int = combos_container.get_child_count()
	if child_count > 0:
		var last_ob: OptionButton = combos_container.get_child(child_count - 1) as OptionButton
		combos_container.remove_child(last_ob)
		last_ob.queue_free()

func get_label_text(row_num: int) -> String:
	var prefix: String = "G+" if is_out_mode else "G-"
	return prefix + "(" + str(row_num) + ")"

func update_labels() -> void:
	for i: int in range(row_containers.size()):
		var row: HBoxContainer = row_containers[i]
		var label: Label = row.get_child(2) as Label
		label.text = get_label_text(i + 1)

func set_locked(value: bool) -> void:
	locked = value
	for row: HBoxContainer in row_containers:
		var add_button: Button = row.get_child(0) as Button
		var remove_button: Button = row.get_child(1) as Button
		add_button.disabled = locked
		remove_button.disabled = locked
		var combos_container: HBoxContainer = row.get_child(4) as HBoxContainer
		for child: Node in combos_container.get_children():
			var ob: OptionButton = child as OptionButton
			ob.disabled = locked

func switch_mode() -> void:
	if locked:
		return  # Perhaps allow switch even if locked? But for now, prevent if locked
	var current_data: Array[Array] = get_data()
	var inverted: Array[Array] = []
	for _j: int in range(num_vertices):
		inverted.append([])
	for i: int in range(num_vertices):
		for neigh: int in current_data[i]:
			inverted[neigh - 1].append(i + 1)
	is_out_mode = !is_out_mode
	set_data(inverted)
	update_labels()

func get_data() -> Array[Array]:
	var data: Array[Array] = []
	for row: HBoxContainer in row_containers:
		var row_data: Array[int] = []
		var combos_container: HBoxContainer = row.get_child(4) as HBoxContainer
		for child: Node in combos_container.get_children():
			var ob: OptionButton = child as OptionButton
			if ob.selected_index >= 0:
				row_data.append(int(ob.text))
		data.append(row_data)
	return data

func set_data(data: Array[Array]) -> void:
	if data.size() != num_vertices:
		return
	for i: int in range(num_vertices):
		var row: HBoxContainer = row_containers[i]
		var combos_container: HBoxContainer = row.get_child(4) as HBoxContainer
		for child: Node in combos_container.get_children():
			combos_container.remove_child(child)
			child.queue_free()
		for neigh: int in data[i]:
			var ob: OptionButton = create_option_button()
			ob.select(neigh - 1)
			combos_container.add_child(ob)
