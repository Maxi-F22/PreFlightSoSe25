extends CharacterBody3D

@export var speed: float = 3.0

@export var gravity: float = 9.8 * 5  # 5x normal gravity
@export var jump_strength: float = 10.0
@export var jump_interval: float = 3.0  # How often enemies jump
@onready var _enemy_sounds: = $SoundManagerEnemy  as Node3D

var target: Node3D
var jump_timer: Timer

var enemy_model : Node3D
var enemy_model_squished : Node3D

var is_dead: bool

var sounds_squish : AudioStreamPlayer3D

func _ready():
	add_to_group("enemies")
	target = get_tree().get_root().get_node("Main/Player")
	if not target:
		push_warning("Player not found!")

	sounds_squish = _enemy_sounds.get_node("Squish")

	# Jump timer
	jump_timer = Timer.new()
	jump_timer.wait_time = jump_interval
	jump_timer.one_shot = false
	jump_timer.autostart = true
	add_child(jump_timer)
	jump_timer.timeout.connect(_on_jump_timeout)

	enemy_model = $EnemyModel as Node3D
	enemy_model_squished = $EnemyModelSquished as Node3D
	enemy_model.visible = true
	enemy_model_squished.visible = false


func _physics_process(delta):
	if is_dead:
		return
		
	if not is_on_floor():
		velocity += get_gravity() * delta

 	# Move toward the target
	if target and is_instance_valid(target) and position.distance_to(target.position) < 10:
		var direction = (target.global_position - global_position)
		direction.y = 0
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	elif position.distance_to(target.position) > 100:
		die()
	else:
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()


func die():
	if not sounds_squish.playing:
		sounds_squish.play()
	is_dead = true
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3(0,0,0)
	enemy_model.visible = false
	enemy_model_squished.visible = true
	await get_tree().create_timer(1.0).timeout
	queue_free()

	
func _on_jump_timeout():
	if is_on_floor():
		velocity.y = jump_strength
