extends Node3D

@export var spawn_obj = preload("res://Assets/Prefabs/EnemyPrefab.tscn")

@export var spawn_interval: float = 2.0  # seconds between spawns
#@export var platform_size:Vector2
var platform_size:Vector2
var timer: Timer


func _ready():
	var floor_obj = $Floor
	platform_size = Vector2(floor_obj.size.x, floor_obj.size.z)
	# Create and configure a timer to handle regular spawning
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	spawn_enemy(get_random_position_on_platform())

func spawn_enemy(position: Vector3):
	if spawn_obj:
		var enemy_instance = spawn_obj.instantiate()
		add_child(enemy_instance)
		enemy_instance.global_position = position
	else:
		push_error("Enemy scene not loaded!")

func get_random_position_on_platform() -> Vector3:
	var x = randf_range(-platform_size.x / 2, platform_size.x / 2)
	var z = randf_range(-platform_size.y / 2, platform_size.y / 2)
	var y = global_position.y + 1  # Adjust if your platform is raised
	return Vector3(x, y, z)
