extends CharacterBody2D

@onready var anim = $AnimatedSprite2D
@export var health: int = 100 

const BASE_SPEED = 200
var current_speed: float = BASE_SPEED
var is_attacking: bool = false
signal health_depleted

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		perform_attack()
		return
	
	if is_attacking:
		return
	
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = current_speed*direction
	move_and_slide()
	update_animation(direction)
	const DAMAGE_RATE = 5
	var overlapping_mobs = []
	for body in $Hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			overlapping_mobs.append(body)
			
	if overlapping_mobs.size()>0:
		health -= DAMAGE_RATE*overlapping_mobs.size()*delta
		$HealthBar.value = health
		if health <= 0:
			health_depleted.emit()
			
func perform_attack() -> void:
	is_attacking = true
	var last_anim = anim.animation
	var direction_suffix = ""
	
	if "left" in last_anim:
		direction_suffix = "_left"
	elif "right" in last_anim:
		direction_suffix = "_right"
	elif "up" in last_anim:
		direction_suffix = "_up"
	else:
		direction_suffix = "_down"
		
	var attack_type = "attack" if randf()>0.5 else "attack2"
	var attack_anim = attack_type + direction_suffix
	anim.play(attack_anim)
	await anim.animation_finished
	is_attacking = false
	
func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
			anim.play(get_idle_animation())
			return
	if abs(direction.x) > abs(direction.y):
		if direction.x>0:
			anim.play("run_right")
		else:
			anim.play("run_left")
	else:
		if direction.y > 0:
			anim.play("run_down")
		else:
			anim.play("run_up")
			
func get_idle_animation() -> String:
	var last_anim = anim.animation
	if "left" in last_anim:
		return "idle_left"
	elif "right" in last_anim:
		return "idle_right"
	elif "up" in last_anim:
		return "idle_up"
	else:
		return "idle_down"
