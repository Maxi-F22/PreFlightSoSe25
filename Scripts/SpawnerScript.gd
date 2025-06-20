extends Node3D

@export var spawn_obj = preload("res://Assets/Prefabs/EnemyPrefab.tscn")

@export var spawn_interval: float = 2.0  # seconds between spawns
@export var enemy_scene: PackedScene
@export var jump_interval: float = 3.0  # How often enemies jump
#@export var platform_size:Vector2
var platform_size:Vector2
var spawn_timer: Timer
var jump_timer: Timer



var enemies: Array[Node3D] = []

func _ready():
	# Get floor reference
	var floor_obj = $Floor
	platform_size = Vector2(floor_obj.size.x, floor_obj.size.z)

	# Spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.autostart = true
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timeout)

	# Jump timer
	jump_timer = Timer.new()
	jump_timer.wait_time = jump_interval
	jump_timer.one_shot = false
	jump_timer.autostart = true
	add_child(jump_timer)
	jump_timer.timeout.connect(_on_jump_timeout)

func _on_spawn_timeout():
	var enemy = spawn_enemy(get_random_position_on_floor())
	if enemy:
		enemies.append(enemy)

func _on_jump_timeout():
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("jump") :
				enemy.jump()

func spawn_enemy(position: Vector3) -> Node3D:
	if spawn_obj:
		var enemy_instance = spawn_obj.instantiate()
		add_child(enemy_instance)
		enemy_instance.global_position = position
		return enemy_instance
	else:
		push_error("Enemy scene not loaded!")
		return null

func get_random_position_on_floor() -> Vector3:
	var x = randf_range(-platform_size.x / 2, platform_size.x / 2)
	var z = randf_range(-platform_size.y / 2, platform_size.y / 2)
	var y = global_position.y + 1  # Adjust if your platform is raised
	return Vector3(x, y, z)
