class_name CharacterEntity
extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal entity_died(entity: CharacterEntity)

var max_hp: int = 100
var current_hp: int = 100
var move_speed: float = 180.0
var is_dead: bool = false
var animated_sprite: AnimatedSprite2D
var collision_shape: CollisionShape2D

func setup_entity(hp_val: int, speed_val: float, sheet_path: String, collider_radius: float) -> void:
	max_hp = hp_val
	current_hp = hp_val
	move_speed = speed_val
	is_dead = false

	collision_shape = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = collider_radius
	collision_shape.shape = circle
	add_child(collision_shape)

	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = _build_sprite_frames(sheet_path)
	animated_sprite.play("idle")
	add_child(animated_sprite)

func _build_sprite_frames(sheet_path: String) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	var tex: Texture2D = load(sheet_path)

	var frame_0: AtlasTexture = AtlasTexture.new()
	frame_0.atlas = tex
	frame_0.region = Rect2(0, 0, 32, 32)

	var frame_1: AtlasTexture = AtlasTexture.new()
	frame_1.atlas = tex
	frame_1.region = Rect2(32, 0, 32, 32)

	var frame_2: AtlasTexture = AtlasTexture.new()
	frame_2.atlas = tex
	frame_2.region = Rect2(64, 0, 32, 32)

	var frame_3: AtlasTexture = AtlasTexture.new()
	frame_3.atlas = tex
	frame_3.region = Rect2(96, 0, 32, 32)

	if not frames.has_animation("idle"):
		frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 4.0)
	frames.add_frame("idle", frame_0)
	frames.add_frame("idle", frame_1)

	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", 9.0)
	frames.add_frame("walk", frame_1)
	frames.add_frame("walk", frame_0)
	frames.add_frame("walk", frame_2)
	frames.add_frame("walk", frame_0)

	frames.add_animation("hit")
	frames.set_animation_loop("hit", false)
	frames.set_animation_speed("hit", 10.0)
	frames.add_frame("hit", frame_3)
	frames.add_frame("hit", frame_0)

	return frames

func update_movement_animation(dir: Vector2) -> void:
	if animated_sprite == null or is_dead:
		return
	if dir.x < -0.05:
		animated_sprite.flip_h = true
	elif dir.x > 0.05:
		animated_sprite.flip_h = false

	if animated_sprite.animation == "hit" and animated_sprite.is_playing():
		return

	if dir.length_squared() > 4.0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func take_damage(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	play_hit_flash()
	if current_hp <= 0:
		die()

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)
	if animated_sprite != null:
		var tween: Tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(0.5, 1.4, 0.7, 1.0), 0.1)
		tween.tween_property(animated_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)

func play_hit_flash() -> void:
	if animated_sprite == null:
		return
	animated_sprite.play("hit")
	var tween: Tween = create_tween()
	tween.tween_property(animated_sprite, "scale", Vector2(1.25, 0.8), 0.06)
	tween.tween_property(animated_sprite, "scale", Vector2(1.0, 1.0), 0.12)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	entity_died.emit(self)
