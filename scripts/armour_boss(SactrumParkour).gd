extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var hit_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var max_health: int = 200
@export var current_health: int = 200
@export var damage_to_player: int = 10
@export var chase_speed: float = 150.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 300.0

var player: CharacterBody2D = null
var is_attacking := false
var is_dead := false
var can_attack := true

func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_entered)
		attack_area.body_exited.connect(_on_attack_area_exited)

	if player and player.has_node("SwordArea"):
		player.get_node("SwordArea").body_entered.connect(_on_sword_area_entered)

func _physics_process(delta: float) -> void:
	if is_dead or not player:
		return

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance := global_position.distance_to(player.global_position)

	if distance > detection_range:
		idle_state()
		return

	if distance <= attack_range and can_attack:
		perform_attack()
		return

	chase_player()

func idle_state() -> void:
	velocity = Vector2.ZERO
	anim.play("idle")
	move_and_slide()

func chase_player() -> void:
	var dir: float = sign(player.global_position.x - global_position.x)
	velocity.x = dir * chase_speed

	sprite.flip_h = dir < 0
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

	anim.play("attack")
	await anim.animation_finished

	if attack_area:
		attack_area.monitoring = false

	is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_area_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.start_damage_from(self, damage_to_player)

func _on_attack_area_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.stop_damage_from(self)

func take_damage(damage: int) -> void:
	if is_dead:
		return

	current_health -= damage

	if hit_sound:
		hit_sound.play()

	modulate = Color(2, 2, 2)
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

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

func get_damage() -> int:
	return damage_to_player
