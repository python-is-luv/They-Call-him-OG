extends Node2D

@export var asteroid_scene: PackedScene
@export var spawn_interval := 1.5
@onready var start_screen = $StartScreen
@onready var scene_timer: Timer = $SceneTimer
@onready var time_label: Label = $CanvasLayer/TimeLabel
var spawn_timer := 0.0
var screen_size: Vector2
var game_started := false

func _ready():
	screen_size = get_viewport_rect().size
	time_label.text = "Time Left: 01:00"


func _process(delta):
	if not game_started:
		return
	
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_asteroid()
		spawn_timer = 0.0
	
	update_timer_label()


func spawn_asteroid():
	var asteroid = asteroid_scene.instantiate()
	var random_x = randf_range(0, screen_size.x)
	asteroid.position = Vector2(random_x, -50)
	add_child(asteroid)


func update_timer_label():
	var time_left := int(scene_timer.time_left)
	var minutes := time_left / 60
	var seconds := time_left % 60
	time_label.text = "Time Left: %02d:%02d" % [minutes, seconds]


func _on_start_screen_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		game_started = true
		start_screen.visible = false
		scene_timer.start()

func _on_scene_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/SanctrumParkour/SanctrumParkour.tscn")
	
