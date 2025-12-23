extends Area2D

func _ready():
	# Connect the area_entered signal to detect collisions
	area_entered.connect(_on_area_entered)
	# Or if enemy is a body (CharacterBody2D, RigidBody2D, etc.)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area):
	# Check if the collided area is an enemy
	if area.is_in_group("enemy"):
		area.queue_free()  # Remove the enemy

func _on_body_entered(body):
	# If your enemy is a CharacterBody2D or similar
	if body.is_in_group("enemy"):
		body.queue_free()  # Remove the enemy
