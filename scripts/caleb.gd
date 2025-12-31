extends CharacterBody2D

@export_group("Behavior")
@export var can_jump: bool = false

@export_group("Stats")
@export var move_speed: float = 200.0
@export var jump_force: float = -450.0
@export var damage_amount: int = 4
@export var attack_range: float = 60.0
@export var detection_range: float = 400.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var ledge_check: RayCast2D = $LedgeCheck

static var target_registry: Dictionary = {}

var player: CharacterBody2D = null
var current_target: Node2D = null
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_attacking: bool = false

func _ready() -> void:
	add_collision_exception_with(get_tree().get_first_node_in_group("player"))
	player = get_tree().get_first_node_in_group("player")
	
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, 20)
		move_and_slide()
		return

	current_target = get_valid_target()
	
	if current_target:
		_behavior_combat()
	else:
		if can_jump:
			_behavior_follow_advanced()
		else:
			_behavior_follow_simple()
	move_and_slide()
	_update_animation()
	
	if can_jump and velocity.x != 0:
		ledge_check.position.x = sign(velocity.x) * 20
		ledge_check.force_raycast_update()

func get_valid_target() -> Node2D:
	if current_target and is_instance_valid(current_target) and not current_target.is_dead:
		return current_target
	
	if target_registry.has(get_instance_id()):
		target_registry.erase(get_instance_id())
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	var best_candidate = null
	var closest_dist = detection_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead: continue
		
		var is_taken = false
		for npc_id in target_registry:
			if target_registry[npc_id] == enemy and npc_id != get_instance_id():
				is_taken = true
				break
		
		if not is_taken:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				best_candidate = enemy
	
	if best_candidate:
		target_registry[get_instance_id()] = best_candidate
		
	return best_candidate

func _behavior_combat() -> void:
	var dist = global_position.distance_to(current_target.global_position)
	var dir = sign(current_target.global_position.x - global_position.x)
	
	if dist <= attack_range:
		start_attack()
	else:
		velocity.x = dir * move_speed
		if can_jump and is_on_wall() and is_on_floor():
			velocity.y = jump_force

func _behavior_follow_simple() -> void:
	if not player: return
	var dist = global_position.distance_to(player.global_position)
	
	if dist > 100:
		var dir = sign(player.global_position.x - global_position.x)
		velocity.x = dir * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

func _behavior_follow_advanced() -> void:
	if not player: return
	var dist = global_position.distance_to(player.global_position)
	var dir = sign(player.global_position.x - global_position.x)
	
	if dist > 80:
		velocity.x = dir * move_speed
		
		if is_on_wall() and is_on_floor():
			velocity.y = jump_force
			
		if player.global_position.y < global_position.y - 50 and is_on_floor():
			if abs(player.global_position.x - global_position.x) < 100:
				velocity.y = jump_force

		if is_on_floor() and not ledge_check.is_colliding():
			if (dir > 0 and player.global_position.x > global_position.x) or \
			   (dir < 0 and player.global_position.x < global_position.x):
				velocity.y = jump_force
			else:
				velocity.x = 0
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)

func start_attack() -> void:
	is_attacking = true
	velocity.x = 0
	
	if attack_area:
		attack_area.monitoring = true
	
	var anim_name = "attack1" if randf() > 0.5 else "attack2"
	anim.play(anim_name)
	await anim.animation_finished
	
	if attack_area:
		attack_area.monitoring = false
	is_attacking = false

func _update_animation() -> void:
	if is_attacking: return
	
	if velocity.x != 0:
		anim.play("run")
		anim.flip_h = velocity.x < 0
		if attack_area:
			attack_area.scale.x = -1 if velocity.x < 0 else 1
	else:
		anim.play("idle")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage_amount)

func take_damage(_amount: int) -> void:
	anim.play("hurt")
