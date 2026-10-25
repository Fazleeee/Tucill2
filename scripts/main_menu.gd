extends Control

var audio_controller: AudioController
var stats_label: Label
var bgm_slider: HSlider
var sfx_slider: HSlider
var status_label: Label

func _ready() -> void:
	audio_controller = AudioController.new()
	add_child(audio_controller)
	audio_controller.play_bgm()
	_build_ui()
	_refresh_stats_display()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.08, 0.10, 0.16, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(520.0, 470.0)
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = Color(0.13, 0.16, 0.25, 0.98)
	card_style.border_color = Color(0.22, 0.74, 0.97, 0.9)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(12)
	card_style.set_content_margin_all(28)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var title: Label = Label.new()
	title.text = "NEON BREACH: TACTICAL ARENA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.22, 0.74, 0.97))
	vbox.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "WASD/Arrows: Move  |  Mouse: Raycast Aim & Shoot  |  Space: Dash"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	vbox.add_child(subtitle)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.55))
	vbox.add_child(stats_label)

	var saved: Dictionary = SaveSystem.load_data()

	var bgm_row: HBoxContainer = HBoxContainer.new()
	var bgm_lbl: Label = Label.new()
	bgm_lbl.text = "BGM Volume"
	bgm_lbl.custom_minimum_size = Vector2(120.0, 0.0)
	bgm_row.add_child(bgm_lbl)

	bgm_slider = HSlider.new()
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 1.0
	bgm_slider.step = 0.05
	bgm_slider.value = float(saved.get("bgm_volume", 0.7))
	bgm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bgm_slider.value_changed.connect(_on_audio_slider_changed)
	bgm_row.add_child(bgm_slider)
	vbox.add_child(bgm_row)

	var sfx_row: HBoxContainer = HBoxContainer.new()
	var sfx_lbl: Label = Label.new()
	sfx_lbl.text = "SFX Volume"
	sfx_lbl.custom_minimum_size = Vector2(120.0, 0.0)
	sfx_row.add_child(sfx_lbl)

	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = float(saved.get("sfx_volume", 0.85))
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.value_changed.connect(_on_audio_slider_changed)
	sfx_row.add_child(sfx_slider)
	vbox.add_child(sfx_row)

	var start_btn: Button = _create_styled_button("START MISSION", Color(0.14, 0.52, 0.78))
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	var reset_btn: Button = _create_styled_button("RESET SAVE DATA", Color(0.32, 0.36, 0.48))
	reset_btn.pressed.connect(_on_reset_pressed)
	vbox.add_child(reset_btn)

	var quit_btn: Button = _create_styled_button("EXIT GAME", Color(0.62, 0.18, 0.22))
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)

	status_label = Label.new()
	status_label.text = ""
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.62))
	vbox.add_child(status_label)

func _create_styled_button(label_text: String, bg_col: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(0.0, 42.0)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = bg_col.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover_style)
	return btn

func _refresh_stats_display() -> void:
	var data: Dictionary = SaveSystem.load_data()
	var hi: int = int(data.get("high_score", 0))
	var wave: int = int(data.get("best_wave", 1))
	var kills: int = int(data.get("total_kills", 0))
	stats_label.text = "Saved Records  —  High Score: %d  |  Best Wave: %d  |  Total Kills: %d" % [hi, wave, kills]

func _on_audio_slider_changed(_val: float) -> void:
	if bgm_slider == null or sfx_slider == null:
		return
	audio_controller.set_bgm_volume(bgm_slider.value)
	audio_controller.set_sfx_volume(sfx_slider.value)
	SaveSystem.update_audio_settings(bgm_slider.value, sfx_slider.value)
	if bgm_slider.value > 0.01:
		audio_controller.play_bgm()
	else:
		audio_controller.stop_bgm()

func _on_start_pressed() -> void:
	audio_controller.play_sfx("pickup")
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_reset_pressed() -> void:
	SaveSystem.reset_data()
	audio_controller.play_sfx("hit")
	_refresh_stats_display()
	status_label.text = "Save data has been reset."

func _on_quit_pressed() -> void:
	get_tree().quit()
