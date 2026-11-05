extends Character
class_name PlayerCharacter;

# Binty and Glinty both use this scene. The only difference between them is char_type (their look).
#
# How it fits together:
#   - Input is read once per frame into move_input and a few BufferedButtons (jump, roll, attack).
#   - Exactly one state runs at a time (see states/). The state decides what happens next and sets velocity.
#   - This script owns the shared helpers states use (moving, gravity, facing) and calls move_and_slide() once.
#   - Health, getting hurt and dying come from Character. What happens after a death (ghost, lost life,
#     Death's scene) is DeathManager's job; this script just reports it through Signals.player_died.
# All tuning numbers live in CharStats.

signal state_changed(previous: Enums.PLAYER_STATES, next: Enums.PLAYER_STATES);

@export var char_type: Enums.CHARACTERS;
@export var is_p1 := true;
@export var debug_states := false;

#region CONSTANTS ==================================================================================
const SHAPE_NORMAL: CapsuleShape3D = preload("res://resources/shapes/player_shape_normal.tres");
const SHAPE_ROLL: CapsuleShape3D = preload("res://resources/shapes/player_shape_roll.tres");
const BODY_NORMAL: CapsuleMesh = preload("res://resources/meshes/test_body.tres");
const BODY_ROLL: CapsuleMesh = preload("res://resources/meshes/test_body_short.tres");

# One scene per swing in CharStats.ATTACK_COMBO, in the same order.
const SWING_ATTACKS: Array[PackedScene] = [
  preload("res://scenes/attacks/swing_attack_1.tscn"),
  preload("res://scenes/attacks/swing_attack_2.tscn"),
  preload("res://scenes/attacks/swing_attack_3.tscn"),
];
const GHOST_ALPHA := 0.35;

const TERRAIN_LAYER_MASK := 1; # Physics layer 1 is "terrain" (see Project Settings > Layer Names).

# Placeholder looks until real models exist. Same moves, different colour.
var PLACEHOLDER_COLORS := {
  Enums.CHARACTERS.BINTY: Color(1.0, 0.85, 0.1),
  Enums.CHARACTERS.GLINTY: Color(0.25, 0.75, 0.3),
};
#endregion =========================================================================================

#region INPUT ======================================================================================
# One button's state, with "buffering": a press still counts for a short while after it happened,
# and each press can only be used once.
class BufferedButton:
  var held := false;
  var held_time := 0.0;
  var _used := false;

  func update(is_held: bool, time_held: float) -> void:
    if !is_held: _used = false;
    held = is_held;
    held_time = time_held;
  #/update

  # Pressed recently and not used up yet.
  func is_buffered() -> bool:
    return held && !_used && held_time <= CharStats.INPUT_BUFFER_TIME;
  #/is_buffered

  # Pressed recently, even if that press was already used. Lets a jump pressed during a flap still fire on landing.
  func was_pressed_recently() -> bool:
    return held && held_time <= CharStats.INPUT_BUFFER_TIME;
  #/was_pressed_recently

  func consume() -> void:
    _used = true;
  #/consume
#/BufferedButton

var move_input := Vector2.ZERO;
var jump := BufferedButton.new();
var roll := BufferedButton.new();
var attack := BufferedButton.new();
#endregion =========================================================================================

#region STATE ======================================================================================
var state: Enums.PLAYER_STATES = Enums.PLAYER_STATES.FALL;
var _current_state: PlayerState;
var _states := {};

var time_since_grounded := 0.0;   # For coyote time.
var can_flap := true;              # One flap per time in the air. Reset on landing.
var carried_speed := 0.0;          # Roll speed kept through a roll-jump until landing. 0 = none.
var attack_index := 0;             # Which swing in the combo comes next.
var hurt_direction := Vector3.ZERO; # Which way the last hit knocked us.
var _camera_zones: Array[CameraZone] = []; # Zones we're standing in. The most recently entered one wins.
var _normal_collision_layer := 0;
var _normal_collision_mask := 0;
#endregion =========================================================================================

#region BUILT IN ===================================================================================
func _ready() -> void:
  _max_health = CharStats.MAX_HEALTH;
  _cur_health = _max_health;
  $InvulnTimer.wait_time = CharStats.INVULNERABLE_TIME;
  _normal_collision_layer = collision_layer;
  _normal_collision_mask = collision_mask;
  if is_p1:
    Global.p1_char = self;
  else:
    Global.p2_char = self;
  #/if

  _apply_placeholder_look();
  _states = {
    Enums.PLAYER_STATES.GROUNDED: PlayerGroundedState.new(self),
    Enums.PLAYER_STATES.JUMP: PlayerJumpState.new(self),
    Enums.PLAYER_STATES.FALL: PlayerFallState.new(self),
    Enums.PLAYER_STATES.FLAP: PlayerFlapState.new(self),
    Enums.PLAYER_STATES.ROLL: PlayerRollState.new(self),
    Enums.PLAYER_STATES.ATTACK: PlayerAttackState.new(self),
    Enums.PLAYER_STATES.HURT: PlayerHurtState.new(self),
    Enums.PLAYER_STATES.GHOST: PlayerGhostState.new(self),
    Enums.PLAYER_STATES.DEAD: PlayerDeadState.new(self),
  };
  change_state(Enums.PLAYER_STATES.FALL);
#/_ready

func _physics_process(delta: float) -> void:
  _read_input();
  _update_invulnerable_blink();
  time_since_grounded = 0.0 if is_on_floor() else time_since_grounded + delta;

  _current_state.time_in_state += delta;
  _current_state.physics_update(delta);
  move_and_slide();
#/_physics_process
#endregion =========================================================================================

#region STATE MACHINE ==============================================================================
func change_state(next: Enums.PLAYER_STATES) -> void:
  if _current_state != null && next == state: return;

  var previous: Enums.PLAYER_STATES = state;
  if _current_state != null: _current_state.exit(next);

  state = next;
  _current_state = _states[next];
  _current_state.time_in_state = 0.0;
  _current_state.enter(previous);

  if debug_states: print("%s: %s -> %s" % [name, Enums.PLAYER_STATES.keys()[previous], get_state_name()]);
  state_changed.emit(previous, next);
#/change_state

func get_player_id() -> int:
  return 1 if is_p1 else 2;
#/get_player_id

func get_state_name() -> String:
  return Enums.PLAYER_STATES.keys()[state];
#/get_state_name

# The actions you can start whenever you're on the ground. Returns true if one started.
# Used by Grounded, and by Roll and Attack once they're allowed to be cancelled.
func try_ground_actions() -> bool:
  if jump.was_pressed_recently():
    jump.consume();
    change_state(Enums.PLAYER_STATES.JUMP);
  elif roll.is_buffered():
    roll.consume();
    change_state(Enums.PLAYER_STATES.ROLL);
  elif attack.is_buffered():
    attack.consume();
    change_state(Enums.PLAYER_STATES.ATTACK);
  else:
    return false;
  #/if
  return true;
#/try_ground_actions

# Grounded or Fall, depending on where we are. Used when a timed state (roll, attack) finishes.
func return_to_neutral() -> void:
  change_state(Enums.PLAYER_STATES.GROUNDED if is_on_floor() else Enums.PLAYER_STATES.FALL);
#/return_to_neutral
#endregion =========================================================================================

#region MOVEMENT HELPERS ===========================================================================
# Stick direction in world space, relative to this player's camera. Length 0 to 1, so half-tilt means half speed.
func get_move_direction() -> Vector3:
  var direction := Vector3(move_input.x, 0.0, move_input.y);
  var camera := Global.get_camera_for_player(get_player_id());
  if camera != null: direction = direction.rotated(Vector3.UP, camera.global_rotation.y);
  return direction.limit_length(1.0);
#/get_move_direction

func get_facing_direction() -> Vector3:
  return -global_basis.z;
#/get_facing_direction

func get_horizontal_speed() -> float:
  return Vector2(velocity.x, velocity.z).length();
#/get_horizontal_speed

# Eases horizontal velocity toward the stick direction * max_speed.
# Pushing against your current movement brakes at TURNAROUND_DECELERATION instead (the skid).
func move_horizontally(delta: float, max_speed: float, acceleration: float, deceleration: float) -> void:
  var target := get_move_direction() * max_speed;
  var horizontal := Vector3(velocity.x, 0.0, velocity.z);

  var rate := acceleration;
  if target.is_zero_approx():
    rate = deceleration;
  elif target.dot(horizontal) < 0.0:
    rate = maxf(acceleration, CharStats.TURNAROUND_DECELERATION);
  #/if

  horizontal = horizontal.move_toward(target, rate * delta);
  velocity.x = horizontal.x;
  velocity.z = horizontal.z;
#/move_horizontally

func move_on_ground(delta: float, speed_multiplier := 1.0) -> void:
  move_horizontally(delta, CharStats.RUN_SPEED * speed_multiplier, CharStats.RUN_ACCELERATION, CharStats.RUN_DECELERATION);
#/move_on_ground

# Air steering. A roll-jump keeps its extra speed until you land.
func move_in_air(delta: float) -> void:
  var max_speed := maxf(CharStats.RUN_SPEED, carried_speed);
  move_horizontally(delta, max_speed, CharStats.AIR_ACCELERATION, CharStats.AIR_DECELERATION);
#/move_in_air

func apply_gravity(delta: float, multiplier := 1.0) -> void:
  velocity.y = maxf(velocity.y - _gravity * multiplier * delta, -CharStats.MAX_FALL_SPEED);
#/apply_gravity

# Smoothly turns to face where the stick points.
func turn_toward_input(delta: float) -> void:
  var direction := get_move_direction();
  if direction.is_zero_approx(): return;
  var target_angle := atan2(-direction.x, -direction.z);
  rotation.y = lerp_angle(rotation.y, target_angle, clampf(CharStats.TURN_SPEED * delta, 0.0, 1.0));
#/turn_toward_input

# Instantly faces where the stick points. Used at the start of a roll or swing.
func snap_toward_input() -> void:
  var direction := get_move_direction();
  if direction.is_zero_approx(): return;
  rotation.y = atan2(-direction.x, -direction.z);
#/snap_toward_input

# True if there's ground within the given distance straight below us.
func is_ground_within(distance: float) -> bool:
  var query := PhysicsRayQueryParameters3D.create(global_position, global_position + Vector3.DOWN * distance, TERRAIN_LAYER_MASK, [get_rid()]);
  return !get_world_3d().direct_space_state.intersect_ray(query).is_empty();
#/is_ground_within

func can_coyote_jump() -> bool:
  return time_since_grounded <= CharStats.COYOTE_TIME;
#/can_coyote_jump

# Swaps to the short capsule while rolling, keeping its base on the floor.
func set_roll_shape(is_rolling: bool) -> void:
  var shape: CapsuleShape3D = SHAPE_ROLL if is_rolling else SHAPE_NORMAL;
  $Collision.shape = shape;
  $Collision.position.y = shape.height * 0.5;
  $Model/Body.mesh = BODY_ROLL if is_rolling else BODY_NORMAL;
  $Model/Body.position.y = $Collision.position.y;
#/set_roll_shape

func enter_camera_zone(zone: CameraZone) -> void:
  if !_camera_zones.has(zone): _camera_zones.append(zone);
#/enter_camera_zone

func exit_camera_zone(zone: CameraZone) -> void:
  _camera_zones.erase(zone);
#/exit_camera_zone

func get_camera_zone() -> CameraZone:
  return null if _camera_zones.is_empty() else _camera_zones.back();
#/get_camera_zone

func spawn_swing(index: int) -> void:
  var swing: Dictionary = CharStats.ATTACK_COMBO[index];
  var attack := _spawn_attack(SWING_ATTACKS[index], swing.time);
  attack.damage = swing.damage;
  attack.knockback = swing.knockback;
  attack.hit_stop = swing.hit_stop;
#/spawn_swing
#endregion =========================================================================================

#region LIFE AND DEATH =============================================================================
func is_alive() -> bool:
  return state != Enums.PLAYER_STATES.GHOST && state != Enums.PLAYER_STATES.DEAD;
#/is_alive

func is_ghost() -> bool:
  return state == Enums.PLAYER_STATES.GHOST;
#/is_ghost

func get_partner() -> PlayerCharacter:
  return Global.p2_char if is_p1 else Global.p1_char;
#/get_partner

# Called by DeathManager when our partner is still alive.
func become_ghost() -> void:
  change_state(Enums.PLAYER_STATES.GHOST);
#/become_ghost

# Back to full health at a spot, with a short grace period of invulnerability.
func revive_at(spawn: Transform3D) -> void:
  global_transform = spawn;
  velocity = Vector3.ZERO;
  _cur_health = _max_health;
  set_ghost_body(false);
  change_state(Enums.PLAYER_STATES.FALL);
  $InvulnTimer.start();
  Signals.player_health_changed.emit(self, _cur_health);
  Signals.player_revived.emit(self);
#/revive_at

# Ghosts pass through everything and can't be touched or collect pickups.
func set_ghost_body(is_ghost_body: bool) -> void:
  collision_layer = 0 if is_ghost_body else _normal_collision_layer;
  collision_mask = 0 if is_ghost_body else _normal_collision_mask;
  _apply_placeholder_look(GHOST_ALPHA if is_ghost_body else 1.0);
#/set_ghost_body

#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _read_input() -> void:
  var buffer: Dictionary = Global.input_manager.p1_input_buffer if is_p1 else Global.input_manager.p2_input_buffer;
  move_input = buffer[Enums.INPUT_BUFFER.MOVE];
  jump.update(buffer[Enums.INPUT_BUFFER.JUMP_HELD], buffer[Enums.INPUT_BUFFER.JUMP_HELD_TIME]);
  roll.update(buffer[Enums.INPUT_BUFFER.ROLL_HELD], buffer[Enums.INPUT_BUFFER.ROLL_HELD_TIME]);
  attack.update(buffer[Enums.INPUT_BUFFER.ATTACK_HELD], buffer[Enums.INPUT_BUFFER.ATTACK_HELD_TIME]);
#/_read_input

func _apply_placeholder_look(alpha := 1.0) -> void:
  var material := StandardMaterial3D.new();
  var color: Color = PLACEHOLDER_COLORS.get(char_type, Color.WHITE);
  material.albedo_color = Color(color, alpha);
  if alpha < 1.0: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;
  $Model/Body.material_override = material;
#/_apply_placeholder_look

# Blink while invulnerable after a hit.
func _update_invulnerable_blink() -> void:
  var blinking: bool = !$InvulnTimer.is_stopped() && is_alive();
  $Model.visible = !blinking || fmod($InvulnTimer.time_left * CharStats.INVULNERABLE_BLINK_RATE, 1.0) < 0.5;
#/_update_invulnerable_blink

#endregion =========================================================================================

#region CHARACTER OVERRIDES ========================================================================
func _on_hurt(_amount: int, from_position: Vector3, _knockback: float) -> void:
  hurt_direction = get_knockback_direction(from_position);
  change_state(Enums.PLAYER_STATES.HURT);
  Signals.player_health_changed.emit(self, _cur_health);
#/_on_hurt

func _on_health_depleted() -> void:
  Signals.player_health_changed.emit(self, _cur_health);
  change_state(Enums.PLAYER_STATES.DEAD);
  Signals.player_died.emit(self);
#/_on_health_depleted

func _on_healed() -> void:
  Signals.player_health_changed.emit(self, _cur_health);
#/_on_healed

# Falling into a pit, crushing, etc: straight to zero, ignoring dodges and invulnerability.
func kill() -> void:
  if !is_alive(): return;
  _cur_health = 0;
  _on_health_depleted();
#/kill
#endregion =========================================================================================
