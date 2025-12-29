extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var attack_area = $AttackArea
@onready var hit_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var max_health: int = 40
@export var current_health: int = 40
@export var damage_to_player: int = 10
@export var chase_speed: float = 150.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 300.0

var player: CharacterBody2D = null
var is_attacking: bool = false
var is_dead: bool = false
var can_attack: bool = true
var last_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player")
	
	if player and player.has_node("SwordArea"):
		var sword_area: Area2D = player.get_node("SwordArea")
		sword_area.body_entered.connect(_on_sword_area_entered)
	
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_entered)

func _physics_process(delta: float) -> void:
	if is_dead or not player:
		return
	
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_range:
		play_idle_animation()
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if distance_to_player <= attack_range and can_attack:
		perform_attack()
		return	
	
	chase_player()

func chase_player() -> void:
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity = direction_to_player * chase_speed
	last_direction = direction_to_player
	
	if direction_to_player.x > 0:
		sprite.flip_h = false
	elif direction_to_player.x < 0:
		sprite.flip_h = true
	
	anim.play("run")
	move_and_slide()

func perform_attack() -> void:
	if is_attacking or not can_attack:
		return
	
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	
	if attack_area:
		attack_area.monitoring = true
	
	var attack_type = "attack" if randf() > 0.5 else "attack2"
	anim.play(attack_type)
	
	await anim.animation_finished
	
	if attack_area:
		attack_area.monitoring = false
	
	is_attacking = false	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_area_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_attacking:
		if body.has_method("take_damage"):
			body.take_damage(damage_to_player)

func play_idle_animation() -> void:
	if not is_attacking:
		anim.play("idle")

func is_currently_attacking() -> bool:
	return is_attacking

func take_damage(damage: int) -> void:
	if is_dead:
		return
	
	current_health -= damage
	
	if hit_sound:
		hit_sound.play()
	
	modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if current_health <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	
	anim.play("death")	
	collision_shape.set_deferred("disabled", true)
	await anim.animation_finished	
	queue_free()

func _on_sword_area_entered(body: Node2D) -> void:
	if body == self:
		take_damage(10)
