extends Node3D

@export var spawn_obj = preload("res://Scenes/enemy.tscn")

@export var spawn_interval: float = 4.0  # seconds between spawns
@export var spawn_height_offset: float = 2.0  # How high above the grid to spawn enemies
@export var spawn_radius: float = 30.0  # Maximum distance from player to spawn enemies
@export var max_enemy_number: int = 20

var grid_map: GridMap
var player: Node3D
var valid_cells: Array = []
var spawn_timer: Timer

func _ready():
	# Get GridMap reference
	grid_map = get_tree().get_root().get_node("Main/GridMap")
	if not grid_map:
		push_error("GridMap not found! Make sure the path is correct.")
		return
	
	# Get player reference
	player = get_tree().get_root().get_node("Main/Player")
	if not player:
		push_error("Player not found! Make sure the path is correct.")
		return
		
	# Cache valid cells for spawning
	update_valid_cells()

	# Spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(on_spawn_timeout)


func update_valid_cells():
	valid_cells.clear()
	
	# Get all used cells in the GridMap
	var cells = grid_map.get_used_cells()
	
	# Filter to get only top-level cells (those with no cell above them)
	for cell in cells:
		# Check if this is a top cell (no cell above it)
		var cell_above = Vector3i(cell.x, cell.y + 1, cell.z)
		if not cell_above in cells:
			valid_cells.append(cell)


func on_spawn_timeout():
	if get_tree().get_nodes_in_group("enemies").size() < max_enemy_number:
		var spawn_position = get_random_position_on_grid()
		if spawn_position:
			spawn_enemy(spawn_position)


func spawn_enemy(spawn_position: Vector3):
	if spawn_obj:
		var enemy_instance = spawn_obj.instantiate()
		add_child(enemy_instance)
		enemy_instance.global_position = spawn_position
	else:
		push_error("Enemy scene not loaded!")
		return null


func get_random_position_on_grid() -> Vector3:
	if valid_cells.is_empty() or not player:
		push_warning("No valid grid cells found for spawning or player not found!")
		return Vector3.ZERO
	
	# Filter cells within spawn_radius of player
	var nearby_cells = []
	
	for cell in valid_cells:
		# Convert cell to world position to check distance
		var cell_world_pos = grid_map.global_transform * grid_map.map_to_local(cell)
		
		# Check horizontal distance only (ignoring height differences)
		var horizontal_distance = Vector2(cell_world_pos.x, cell_world_pos.z).distance_to(
			Vector2(player.global_position.x, player.global_position.z))
		
		if horizontal_distance <= spawn_radius:
			nearby_cells.append(cell)
	
	# If no cells are within range, return zero vector
	if nearby_cells.is_empty():
		push_warning("No valid spawn points within " + str(spawn_radius) + " meters of player!")
		return Vector3.ZERO
	
	# Get a random cell from the filtered list
	var random_cell = nearby_cells[randi() % nearby_cells.size()]
	
	# Convert grid cell to world position
	var cell_position = grid_map.map_to_local(random_cell)
	
	# Adjust position to be on top of the cell with offset
	var y_offset = spawn_height_offset
	
	# Combine the grid map's global transform with the local cell position
	var world_position = grid_map.global_transform * cell_position
	world_position.y += y_offset
	
	return world_position
