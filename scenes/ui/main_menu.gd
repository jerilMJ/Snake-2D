extends Control

var game_scene: PackedScene = preload("res://scenes/levels/level.tscn")


func _on_start_game_pressed():
	get_tree().change_scene_to_packed(game_scene)


func _on_exit_pressed():
	get_tree().quit()
