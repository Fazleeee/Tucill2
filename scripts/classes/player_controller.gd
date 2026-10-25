class_name PlayerController
extends CharacterEntity

signal weapon_fired(hit_enemy: bool)
signal dash_cooldown_changed(ready_ratio: float)

var aim_ray: RayCast2D
var laser_sight: Line2D
var shot_beam: Line2D
var attack_damage: int = 35
var fire_rate: float = 0.22
var fire_timer: float = 0.0
var dash_cooldown: float = 1.6
var dash_timer: float = 0.0
var dash_active_time: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	setup_entity(100, 210.0, "res://assets/sprites/player_sheet.png", 11.0)

	laser_sight = Line2D.new()
	laser_sight.width = 2.0
	laser_sight.default_color = Color(0.22, 0.74, 0.97, 0.45)
	laser_sight.points = PackedVector2Array([Vector2.ZERO, Vector2(200.0, 0.0)])
	add_child(laser_sight)

	shot_beam = Line2D.new()
	shot_beam.width = 5.0
	shot_beam.default_color = Color(0.95, 0.98, 1.0, 0.0)
	shot_beam.points = PackedVector2Array([Vector2.ZERO, Vector2(200.0, 0.0)])
	add_child(shot_beam)

	aim_ray = RayCast2D.new()
	aim_ray.enabled = true
	aim_ray.target_position = Vector2(520.0, 0.0)
	aim_ray.collision_mask = 5
	aim_ray.exclude_parent = true
	add_child(aim_ray)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if fire_timer > 0.0:
		fire_timer = maxf(fire_timer - delta, 0.0)

	if dash_timer > 0.0:
		dash_timer = maxf(dash_timer - delta, 0.0)
		var ratio: float = 1.0 - (dash_timer / dash_cooldown)
		dash_cooldown_changed.emit(clampf(ratio, 0.0, 1.0))
	else:
		dash_cooldown_changed.emit(1.0)

	var input_dir: Vector2 = _read_move_input()

	if dash_active_time > 0.0:
		dash_active_time -= delta
		velocity = dash_direction * (move_speed * 2.65)
	else:
		if _is_dash_pressed() and dash_timer <= 0.0 and input_dir.length_squared() > 0.01:
			dash_direction = input_dir.normalized()
			dash_active_time = 0.14
			dash_timer = dash_cooldown
			velocity = dash_direction * (move_speed * 2.65)
		else:
			velocity = input_dir * move_speed

	move_and_slide()
	update_movement_animation(velocity)
	_update_aim_raycast()

	if _is_fire_pressed() and fire_timer <= 0.0:
		_fire_raycast_weapon()

func _read_move_input() -> Vector2:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	return dir.normalized()

func _is_dash_pressed() -> bool:
	return Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)

func _is_fire_pressed() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _update_aim_raycast() -> void:
	var mouse_world: Vector2 = get_global_mouse_position()
	var aim_dir: Vector2 = (mouse_world - global_position).normalized()
	if aim_dir.length_squared() < 0.001:
		aim_dir = Vector2.RIGHT

	aim_ray.target_position = aim_dir * 540.0
	aim_ray.force_raycast_update()

	var end_local: Vector2 = aim_ray.target_position
	var targeting_enemy: bool = false
	if aim_ray.is_colliding():
		end_local = to_local(aim_ray.get_collision_point())
		var collider: Object = aim_ray.get_collider()
		if collider is EnemyAgent:
			targeting_enemy = true

	laser_sight.points = PackedVector2Array([Vector2.ZERO, end_local])
	if targeting_enemy:
		laser_sight.default_color = Color(1.0, 0.32, 0.32, 0.85)
		laser_sight.width = 2.6
	else:
		laser_sight.default_color = Color(0.22, 0.74, 0.97, 0.45)
		laser_sight.width = 1.8

func _fire_raycast_weapon() -> void:
	fire_timer = fire_rate
	aim_ray.force_raycast_update()

	var end_local: Vector2 = aim_ray.target_position
	var hit_enemy: bool = false

	if aim_ray.is_colliding():
		end_local = to_local(aim_ray.get_collision_point())
		var collider: Object = aim_ray.get_collider()
		if collider is EnemyAgent:
			var enemy: EnemyAgent = collider as EnemyAgent
			enemy.take_damage(attack_damage)
			hit_enemy = true

	shot_beam.points = PackedVector2Array([Vector2.ZERO, end_local])
	shot_beam.default_color = Color(0.98, 0.95, 0.55, 0.95)
	var tween: Tween = create_tween()
	tween.tween_property(shot_beam, "default_color", Color(0.38, 0.85, 1.0, 0.0), 0.11)

	weapon_fired.emit(hit_enemy)
