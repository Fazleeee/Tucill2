class_name AudioController
extends Node

var bgm_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var bgm_volume: float = 0.7
var sfx_volume: float = 0.85

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	var bgm_stream: AudioStream = load("res://assets/audio/bgm_loop.wav")
	bgm_player.stream = bgm_stream
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)

	sfx_streams["shoot"] = load("res://assets/audio/shoot.wav")
	sfx_streams["hit"] = load("res://assets/audio/hit.wav")
	sfx_streams["pickup"] = load("res://assets/audio/pickup.wav")
	sfx_streams["wave_clear"] = load("res://assets/audio/wave_clear.wav")
	sfx_streams["game_over"] = load("res://assets/audio/game_over.wav")

	for i in range(6):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

	var saved: Dictionary = SaveSystem.load_data()
	set_bgm_volume(float(saved.get("bgm_volume", 0.7)))
	set_sfx_volume(float(saved.get("sfx_volume", 0.85)))

func _on_bgm_finished() -> void:
	if bgm_volume > 0.01:
		bgm_player.play()

func play_bgm() -> void:
	if bgm_player != null and not bgm_player.playing and bgm_volume > 0.01:
		bgm_player.play()

func stop_bgm() -> void:
	if bgm_player != null:
		bgm_player.stop()

func play_sfx(sfx_name: String) -> void:
	if sfx_volume <= 0.01 or not sfx_streams.has(sfx_name):
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = sfx_streams[sfx_name]
			player.volume_db = linear_to_db(maxf(sfx_volume, 0.001))
			player.play()
			return
	var fallback: AudioStreamPlayer = sfx_players[0]
	fallback.stream = sfx_streams[sfx_name]
	fallback.volume_db = linear_to_db(maxf(sfx_volume, 0.001))
	fallback.play()

func set_bgm_volume(linear_val: float) -> void:
	bgm_volume = clampf(linear_val, 0.0, 1.0)
	if bgm_player != null:
		if bgm_volume <= 0.01:
			bgm_player.volume_db = -80.0
		else:
			bgm_player.volume_db = linear_to_db(bgm_volume)

func set_sfx_volume(linear_val: float) -> void:
	sfx_volume = clampf(linear_val, 0.0, 1.0)
	for player in sfx_players:
		if sfx_volume <= 0.01:
			player.volume_db = -80.0
		else:
			player.volume_db = linear_to_db(sfx_volume)
