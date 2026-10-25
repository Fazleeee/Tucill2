class_name EnemyAgent
extends CharacterEntity

var target_player: PlayerController
var dungeon_map: DungeonMap
var los_ray: RayCast2D
var current_path: PackedVector2Array = PackedVector2Array()
var path_index: int = 0
var repath_timer: float = 0.0
var attack_cooldown: float = 0.0
var contact_damage: int = 12
var score_value: int = 100
var has_line_of_sight: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 7
	setup_entity(65, 112.0, "res://assets/sprites/enemy_sheet.png", 11.0)

	los_ray = RayCast2D.new()
	los_ray.enabled = true
	los_ray.collision_mask = 3
	los_ray.exclude_parent = true
	add_child(los_ray)

func configure_for_wave(wave: int, player_ref: PlayerController, map_ref: DungeonMap) -> void:
	target_player = player_ref
	dungeon_map = map_ref
	var scaled_hp: int = 55 + (wave - 1) * 15
	var scaled_speed: float = minf(105.0 + float(wave - 1) * 9.0, 175.0)
	max_hp = scaled_hp
	current_hp = scaled_hp
	move_speed = scaled_speed
	contact_damage = 10 + (wave - 1) * 2
	score_value = 100 + (wave - 1) * 25
	repath_timer = randf_range(0.02, 0.25)

func _physics_process(delta: float) -> void:
	if is_dead or target_player == null or target_player.is_dead:
		velocity = Vector2.ZERO
		return

	if attack_cooldown > 0.0:
		attack_cooldown = maxf(attack_cooldown - delta, 0.0)

	_check_line_of_sight()

	repath_timer -= delta
	if repath_timer <= 0.0:
		repath_timer = 0.35
		_recalculate_path()

	var move_dir: Vector2 = _get_next_move_direction()
	var effective_speed: float = move_speed
	if has_line_of_sight:
		effective_speed = move_speed * 1.15

	velocity = move_dir * effective_speed
	move_and_slide()
	update_movement_animation(velocity)

	var dist_to_player: float = global_position.distance_to(target_player.global_position)
	if dist_to_player <= 26.0 and attack_cooldown <= 0.0:
		attack_cooldown = 0.75
		target_player.take_damage(contact_damage)

func _check_line_of_sight() -> void:
	if target_player == null or los_ray == null:
		has_line_of_sight = false
		return
	var to_player: Vector2 = target_player.global_position - global_position
	los_ray.target_position = to_player
	los_ray.force_raycast_update()
	if los_ray.is_colliding():
		var collider: Object = los_ray.get_collider()
		has_line_of_sight = (collider == target_player)
	else:
		has_line_of_sight = false

func _recalculate_path() -> void:
	if dungeon_map == null or target_player == null:
		return
	current_path = dungeon_map.get_navigation_path(global_position, target_player.global_position)
	path_index = 0
	if current_path.size() > 1:
		path_index = 1

func _get_next_move_direction() -> Vector2:
	if has_line_of_sight and target_player != null:
		return (target_player.global_position - global_position).normalized()

	while path_index < current_path.size():
		var next_point: Vector2 = current_path[path_index]
		if global_position.distance_to(next_point) <= 10.0:
			path_index += 1
		else:
			return (next_point - global_position).normalized()

	if target_player != null:
		return (target_player.global_position - global_position).normalized()
	return Vector2.ZERO
