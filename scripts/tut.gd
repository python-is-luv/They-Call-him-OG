extends Node

@export var next_scene: PackedScene

func _process(_delta):
	if get_tree().get_nodes_in_group("enemy").is_empty():
		get_tree().change_scene_to_packed(next_scene)
