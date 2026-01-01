extends Node2D

@export var next_scene: PackedScene

func _ready():
	$DieZone.restart_level.connect(_on_restart_level)

func _process(_delta):
	if get_tree().get_nodes_in_group("enemy").is_empty():
		change_scene()

func change_scene():
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)

func _on_restart_level() -> void:
	get_tree().reload_current_scene()
