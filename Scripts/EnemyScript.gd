extends CharacterBody3D

@export var speed: float = 3.0
@export var health: int = 100
@export var target_node_path: NodePath  # Assign in the editor (e.g., the player)

@export var gravity: float = 9.8 * 5  # 5x normal gravity
@export var jump_strength: float = 10.0

var target: Node3D


func _ready():
	add_to_group("enemies")
	target = get_tree().get_root().get_node("Main/Player")
	if not target:
		push_warning("Player not found!")
	

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
 	# Move toward the target
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position)
		direction.y = 0
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	move_and_slide()
func move_toward_target():
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
#Jump Function
func jump():
	if is_on_floor():
		velocity.y = jump_strength
func die():
	queue_free()
