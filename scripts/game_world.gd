extends Node2D

var audio_controller: AudioController
var dungeon_map: DungeonMap
var player: PlayerController
var enemies_container: Node2D
var items_container: Node2D

var current_score: int = 0
var high_score: int = 0
var current_wave: int = 1
var session_kills: int = 0
var active_enemies: int = 0
var is_game_over: bool = false

var hp_bar: ProgressBar
var hp_label: Label
var dash_bar: ProgressBar
var score_label: Label
var wave_label: Label
var enemies_label: Label
var banner_label: Label
var pause_panel: PanelContainer
var game_over_panel: PanelContainer
var final_summary_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved: Dictionary = SaveSystem.load_data()
	high_score = int(saved.get("high_score", 0))

	audio_controller = AudioController.new()
	add_child(audio_controller)
	audio_controller.play_bgm()

	var game_layer: Node2D = Node2D.new()
	game_layer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game_layer)

	dungeon_map = DungeonMap.new()
	game_layer.add_child(dungeon_map)

	items_container = Node2D.new()
	game_layer.add_child(items_container)

	enemies_container = Node2D.new()
	game_layer.add_child(enemies_container)

	player = PlayerController.new()
	player.global_position = Vector2(576.0, 320.0)
	player.health_changed.connect(_on_player_health_changed)
	player.entity_died.connect(_on_player_died)
	player.weapon_fired.connect(_on_player_weapon_fired)
	player.dash_cooldown_changed.connect(_on_player_dash_changed)
	game_layer.add_child(player)

	_build_hud()
	_update_hud()
	_start_wave(1)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and not is_game_over:
			_toggle_pause()

func _build_hud() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var top_bar: PanelContainer = PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(1152.0, 62.0)
	var bar_style: StyleBoxFlat = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.07, 0.09, 0.14, 0.94)
	bar_style.border_color = Color(0.22, 0.74, 0.97, 0.65)
	bar_style.border_width_bottom = 2
	bar_style.set_content_margin_all(10)
	top_bar.add_theme_stylebox_override("panel", bar_style)
	canvas.add_child(top_bar)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	top_bar.add_child(hbox)

	var hp_box: VBoxContainer = VBoxContainer.new()
	hp_label = Label.new()
	hp_label.text = "HP: 100 / 100"
	hp_label.add_theme_font_size_override("font_size", 13)
	hp_box.add_child(hp_label)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(180.0, 16.0)
	hp_bar.max_value = 100.0
	hp_bar.value = 100.0
	hp_bar.show_percentage = false
	var hp_fill: StyleBoxFlat = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.18, 0.82, 0.45)
	hp_fill.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_box.add_child(hp_bar)
	hbox.add_child(hp_box)

	var dash_box: VBoxContainer = VBoxContainer.new()
	var dash_lbl: Label = Label.new()
	dash_lbl.text = "DASH (SPACE)"
	dash_lbl.add_theme_font_size_override("font_size", 13)
	dash_box.add_child(dash_lbl)

	dash_bar = ProgressBar.new()
	dash_bar.custom_minimum_size = Vector2(120.0, 16.0)
	dash_bar.max_value = 1.0
	dash_bar.value = 1.0
	dash_bar.show_percentage = false
	var dash_fill: StyleBoxFlat = StyleBoxFlat.new()
	dash_fill.bg_color = Color(0.22, 0.74, 0.97)
	dash_fill.set_corner_radius_all(4)
	dash_bar.add_theme_stylebox_override("fill", dash_fill)
	dash_box.add_child(dash_bar)
	hbox.add_child(dash_box)

	wave_label = Label.new()
	wave_label.text = "WAVE 1"
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(0.22, 0.74, 0.97))
	hbox.add_child(wave_label)

	enemies_label = Label.new()
	enemies_label.text = "Hostiles: 0"
	enemies_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(enemies_label)

	score_label = Label.new()
	score_label.text = "Score: 0  (Best: 0)"
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.add_theme_font_size_override("font_size", 16)
	score_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.55))
	hbox.add_child(score_label)

	var pause_btn: Button = Button.new()
	pause_btn.text = "PAUSE (ESC)"
	pause_btn.custom_minimum_size = Vector2(110.0, 36.0)
	pause_btn.pressed.connect(_toggle_pause)
	hbox.add_child(pause_btn)

	banner_label = Label.new()
	banner_label.text = ""
	banner_label.position = Vector2(0.0, 74.0)
	banner_label.size = Vector2(1152.0, 36.0)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 20)
	banner_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.55))
	canvas.add_child(banner_label)

	pause_panel = _build_modal_panel(canvas, "GAME PAUSED", false)
	game_over_panel = _build_modal_panel(canvas, "MISSION TERMINATED", true)

func _build_modal_panel(parent_canvas: CanvasLayer, header_text: String, is_gameover_modal: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.visible = false
	panel.custom_minimum_size = Vector2(420.0, 300.0)
	panel.position = Vector2((1152.0 - 420.0) * 0.5, (648.0 - 300.0) * 0.5)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.13, 0.22, 0.97)
	style.border_color = Color(0.22, 0.74, 0.97, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	parent_canvas.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header: Label = Label.new()
	header.text = header_text
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 24)
	header.add_theme_color_override("font_color", Color(0.22, 0.74, 0.97))
	vbox.add_child(header)

	if is_gameover_modal:
		final_summary_label = Label.new()
		final_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		final_summary_label.add_theme_font_size_override("font_size", 16)
		vbox.add_child(final_summary_label)

		var retry_btn: Button = Button.new()
		retry_btn.text = "RETRY MISSION"
		retry_btn.custom_minimum_size = Vector2(0.0, 42.0)
		retry_btn.pressed.connect(_on_retry_pressed)
		vbox.add_child(retry_btn)
	else:
		var resume_btn: Button = Button.new()
		resume_btn.text = "RESUME MISSION"
		resume_btn.custom_minimum_size = Vector2(0.0, 42.0)
		resume_btn.pressed.connect(_toggle_pause)
		vbox.add_child(resume_btn)

		var save_btn: Button = Button.new()
		save_btn.text = "SAVE PROGRESS NOW"
		save_btn.custom_minimum_size = Vector2(0.0, 42.0)
		save_btn.pressed.connect(_on_manual_save_pressed)
		vbox.add_child(save_btn)

	var menu_btn: Button = Button.new()
	menu_btn.text = "RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(0.0, 42.0)
	menu_btn.pressed.connect(_on_return_menu_pressed)
	vbox.add_child(menu_btn)

	return panel

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	var count: int = 3 + (wave_num - 1) * 2
	active_enemies = count
	_show_banner("WAVE %d INCOMING!" % wave_num)

	for i in range(count):
		var enemy: EnemyAgent = EnemyAgent.new()
		var spawn_pos: Vector2 = dungeon_map.get_random_free_world_pos(player.global_position, 240.0)
		enemy.global_position = spawn_pos
		enemy.configure_for_wave(wave_num, player, dungeon_map)
		enemy.entity_died.connect(_on_enemy_died)
		enemies_container.add_child(enemy)

	if wave_num > 1:
		_spawn_collectible(dungeon_map.get_random_free_world_pos(player.global_position, 90.0))

	_update_hud()

func _spawn_collectible(world_pos: Vector2) -> void:
	var item: CollectibleItem = CollectibleItem.new()
	item.global_position = world_pos
	item.collected.connect(_on_item_collected)
	items_container.add_child(item)

func _on_player_weapon_fired(hit_enemy: bool) -> void:
	audio_controller.play_sfx("shoot")
	if hit_enemy:
		audio_controller.play_sfx("hit")

func _on_player_health_changed(cur_hp: int, max_hp_val: int) -> void:
	hp_bar.max_value = float(max_hp_val)
	hp_bar.value = float(cur_hp)
	hp_label.text = "HP: %d / %d" % [cur_hp, max_hp_val]

func _on_player_dash_changed(ratio: float) -> void:
	if dash_bar != null:
		dash_bar.value = ratio

func _on_enemy_died(entity: CharacterEntity) -> void:
	var enemy: EnemyAgent = entity as EnemyAgent
	var drop_pos: Vector2 = enemy.global_position
	current_score += enemy.score_value
	session_kills += 1
	if current_score > high_score:
		high_score = current_score
	enemy.queue_free()

	if randf() < 0.38:
		_spawn_collectible(drop_pos)

	active_enemies = maxi(active_enemies - 1, 0)
	_update_hud()

	if active_enemies <= 0 and not is_game_over:
		audio_controller.play_sfx("wave_clear")
		SaveSystem.update_stats(current_score, current_wave + 1, 0)
		_start_wave(current_wave + 1)

func _on_item_collected(_heal_amt: int, bonus_pts: int) -> void:
	audio_controller.play_sfx("pickup")
	current_score += bonus_pts
	if current_score > high_score:
		high_score = current_score
	_update_hud()

func _on_player_died(_entity: CharacterEntity) -> void:
	if is_game_over:
		return
	is_game_over = true
	audio_controller.play_sfx("game_over")
	var saved: Dictionary = SaveSystem.update_stats(current_score, current_wave, session_kills)
	high_score = int(saved.get("high_score", high_score))
	_update_hud()
	get_tree().paused = true
	pause_panel.visible = false
	final_summary_label.text = "Final Score: %d\nHigh Score: %d\nWave Reached: %d   |   Hostiles Eliminated: %d" % [
		current_score, high_score, current_wave, session_kills
	]
	game_over_panel.visible = true

func _update_hud() -> void:
	if wave_label != null:
		wave_label.text = "WAVE %d" % current_wave
	if enemies_label != null:
		enemies_label.text = "Hostiles: %d" % active_enemies
	if score_label != null:
		score_label.text = "Score: %d  (Best: %d)" % [current_score, high_score]

func _show_banner(msg: String) -> void:
	if banner_label == null:
		return
	banner_label.text = msg
	banner_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween: Tween = create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(banner_label, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.6)

func _toggle_pause() -> void:
	if is_game_over:
		return
	var next_paused: bool = not get_tree().paused
	get_tree().paused = next_paused
	pause_panel.visible = next_paused

func _on_manual_save_pressed() -> void:
	SaveSystem.update_stats(current_score, current_wave, 0)
	audio_controller.play_sfx("pickup")
	_show_banner("PROGRESS SAVED!")

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_return_menu_pressed() -> void:
	SaveSystem.update_stats(current_score, current_wave, session_kills)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
