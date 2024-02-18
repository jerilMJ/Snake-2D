extends Node

var max_players: int = 8
var players: Array[AudioStreamPlayer] = []
var busy_players: Array[AudioStreamPlayer] = []
var sound_queue: Array[String] = []


func _ready():
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.connect("finished", _on_player_finish)
		players.append(player)
		add_child(player)


func _on_player_finish():
	for player in busy_players:
		if not player.playing:
			players.append(player)


func play_sound(sound_path):
	sound_queue.append(sound_path)


func _process(delta):
	if not players.is_empty() and not sound_queue.is_empty():
		var player: AudioStreamPlayer = players.pop_front() as AudioStreamPlayer
		player.stream = load(sound_queue.pop_front())
		player.play()
		busy_players.append(player)
