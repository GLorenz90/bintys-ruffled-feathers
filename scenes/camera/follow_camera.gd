extends Node3D
class_name FollowCamera

# A third-person camera that frames one or more players.
#
#   FollowCamera (sits at the point being looked at, eases toward the players)
#     Pivot      (yaw and pitch)
#       Arm      (SpringArm3D: pulls the camera in front of walls)
#         Camera
#
# By default it follows on its own: it trails the players and drifts round behind them when they run sideways.
# Players can steer it with the right stick (or arrows / right-mouse drag for P1). Left / right steering is
# held for MANUAL_HOLD_TIME, then it goes back to following on its own. Up / down eases back to its natural
# height as soon as you let go. Inside a fixed CameraZone the zone owns the camera and steering is ignored.
# All numbers live in CameraStats.

#region PUBLIC VARS ================================================================================
var targets: Array[PlayerCharacter] = [];
var controller_ids: Array[int] = [];      # Which players' look input steers this camera.
#endregion =========================================================================================

#region PRIVATE VARS ===============================================================================
var _yaw := 0.0;                           # Radians.
var _pitch := deg_to_rad(CameraStats.DEFAULT_PITCH);
var _distance := CameraStats.DEFAULT_DISTANCE;
var _time_since_yaw_input := INF;
var _time_since_pitch_input := INF;
var _yaw_speed := 0.0;                     # Degrees per second from the stick, built up by STICK_ACCELERATION.
var _pitch_speed := 0.0;

# The pitch's S-curve trip back to its natural height (see _ease_pitch_toward).
var _pitch_return_active := false;
var _pitch_return_from := 0.0;
var _pitch_return_to := 0.0;
var _pitch_return_time := 0.0;
var _pitch_return_duration := 0.0;
var _has_snapped := false;

@onready var _pivot: Node3D = $Pivot;
@onready var _arm: SpringArm3D = $Pivot/Arm;
@onready var camera: Camera3D = $Pivot/Arm/Camera;
#endregion =========================================================================================

#region BUILT IN ===================================================================================
func _ready() -> void:
  _arm.collision_mask = 1; # Terrain only, so players never push the camera.
  _arm.margin = CameraStats.COLLISION_MARGIN;
  var shape := SphereShape3D.new();
  shape.radius = CameraStats.COLLISION_RADIUS;
  _arm.shape = shape;
#/_ready

func _physics_process(delta: float) -> void:
  if targets.is_empty(): return;

  var zone := _get_active_zone();
  _update_rotation(delta, zone);
  _update_distance(delta, zone);
  _update_position(delta);
  _apply();
#/_physics_process
#endregion =========================================================================================

#region PUBLIC =====================================================================================
# Jump straight to where this camera wants to be, with no easing. Used on the first frame.
func snap() -> void:
  if targets.is_empty(): return;
  global_position = _get_focus_point();
  _distance = _get_wanted_distance(_get_active_zone());
  _apply();
  _has_snapped = true;
#/snap

# Start from exactly where another camera is. Used when the screen splits, so the new view doesn't jump.
func copy_from(other: FollowCamera) -> void:
  global_position = other.global_position;
  _yaw = other._yaw;
  _pitch = other._pitch;
  _distance = other._distance;
  _time_since_yaw_input = other._time_since_yaw_input;
  _time_since_pitch_input = other._time_since_pitch_input;
  _yaw_speed = 0.0;
  _pitch_speed = 0.0;
  _pitch_return_active = false;
  _has_snapped = true;
  _apply();
#/copy_from

func get_yaw() -> float:
  return _yaw;
#/get_yaw
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _update_rotation(delta: float, zone: CameraZone) -> void:
  # A fixed zone owns the camera completely: no steering, no auto turn.
  if zone != null && zone.fixed_angle:
    _yaw_speed = 0.0;
    _pitch_speed = 0.0;
    _pitch_return_active = false;
    var blend := _sharpness_to_weight(CameraStats.ZONE_BLEND_SHARPNESS, delta);
    _yaw = lerp_angle(_yaw, deg_to_rad(zone.yaw_degrees), blend);
    _pitch = lerp_angle(_pitch, deg_to_rad(zone.pitch_degrees), blend);
    return;
  #/if

  var stick := _read_stick();
  var mouse := _read_mouse_degrees();
  _update_yaw(delta, stick.x, mouse.x);
  _update_pitch(delta, stick.y, mouse.y, zone);
#/_update_rotation

# Left / right. The stick has weight: turning speed builds up and winds down, so small taps make small nudges.
# Steering holds the angle for MANUAL_HOLD_TIME, then auto turn takes over again.
func _update_yaw(delta: float, stick_x: float, mouse_degrees: float) -> void:
  _yaw_speed = _accelerate_turn(_yaw_speed, stick_x * CameraStats.STICK_YAW_SPEED, stick_x, delta);
  if !is_zero_approx(_yaw_speed) || !is_zero_approx(mouse_degrees):
    _yaw -= deg_to_rad(_yaw_speed * delta + mouse_degrees);
    _time_since_yaw_input = 0.0;
    return;
  #/if
  _time_since_yaw_input += delta;
  if _time_since_yaw_input < CameraStats.MANUAL_HOLD_TIME: return;

  # Auto turn: drift behind the players when they run sideways across the screen.
  var right := Vector3(cos(_yaw), 0.0, -sin(_yaw));
  var sideways_speed := _get_average_velocity().dot(right);
  _yaw -= sideways_speed * CameraStats.AUTO_TURN_RATE * delta;
#/_update_yaw

# Up / down, with the same weight as left / right. Once you stop pushing it, it eases back to its natural height.
func _update_pitch(delta: float, stick_y: float, mouse_degrees: float, zone: CameraZone) -> void:
  _pitch_speed = _accelerate_turn(_pitch_speed, stick_y * CameraStats.STICK_PITCH_SPEED, stick_y, delta);
  if !is_zero_approx(_pitch_speed) || !is_zero_approx(mouse_degrees):
    var min_pitch := deg_to_rad(CameraStats.MIN_PITCH);
    var max_pitch := deg_to_rad(CameraStats.MAX_PITCH);
    _pitch = clampf(_pitch - deg_to_rad(_pitch_speed * delta + mouse_degrees), min_pitch, max_pitch);
    if is_equal_approx(_pitch, min_pitch) || is_equal_approx(_pitch, max_pitch): _pitch_speed = 0.0;
    _time_since_pitch_input = 0.0;
    _pitch_return_active = false;
    return;
  #/if
  _time_since_pitch_input += delta;
  if _time_since_pitch_input < CameraStats.PITCH_RETURN_DELAY: return;

  var wanted_pitch := deg_to_rad(zone.pitch_degrees if zone != null && zone.override_pitch else CameraStats.DEFAULT_PITCH);
  _ease_pitch_toward(wanted_pitch, delta);
#/_update_pitch

# Moves a turning speed (degrees per second) toward the target: STICK_ACCELERATION while the stick is held,
# STICK_DECELERATION once it's let go.
func _accelerate_turn(current_speed: float, target_speed: float, stick_amount: float, delta: float) -> float:
  var rate := CameraStats.STICK_ACCELERATION if !is_zero_approx(stick_amount) else CameraStats.STICK_DECELERATION;
  return move_toward(current_speed, target_speed, rate * delta);
#/_accelerate_turn

# Returns the pitch along an S-curve: starts slowly, speeds up in the middle, settles gently at the end.
# The trip takes as long as the angle needs at PITCH_RETURN_SPEED on average. A new target restarts the curve.
func _ease_pitch_toward(wanted_pitch: float, delta: float) -> void:
  if !_pitch_return_active || !is_equal_approx(wanted_pitch, _pitch_return_to):
    if is_equal_approx(_pitch, wanted_pitch): return;
    _pitch_return_active = true;
    _pitch_return_from = _pitch;
    _pitch_return_to = wanted_pitch;
    _pitch_return_time = 0.0;
    var angle := absf(wanted_pitch - _pitch);
    _pitch_return_duration = maxf(angle / deg_to_rad(CameraStats.PITCH_RETURN_SPEED), CameraStats.MIN_PITCH_RETURN_TIME);
  #/if

  _pitch_return_time += delta;
  var progress := clampf(_pitch_return_time / _pitch_return_duration, 0.0, 1.0);
  _pitch = lerpf(_pitch_return_from, _pitch_return_to, smoothstep(0.0, 1.0, progress));
  if progress >= 1.0: _pitch_return_active = false;
#/_ease_pitch_toward

# Combined right-stick (or arrow key) input from every player steering this camera, -1 to 1 on each axis.
func _read_stick() -> Vector2:
  var stick := Vector2.ZERO;
  for player_id in controller_ids:
    stick += _get_input_buffer(player_id)[Enums.INPUT_BUFFER.LOOK];
  #/for
  return stick.limit_length(1.0);
#/_read_stick

# Mouse look this frame, already in degrees. The mouse turns directly with no added weight, since
# acceleration on a mouse feels like lag.
func _read_mouse_degrees() -> Vector2:
  var mouse := Vector2.ZERO;
  for player_id in controller_ids:
    mouse += _get_input_buffer(player_id)[Enums.INPUT_BUFFER.LOOK_MOUSE];
  #/for
  return mouse * CameraStats.MOUSE_SENSITIVITY;
#/_read_mouse_degrees

func _get_input_buffer(player_id: int) -> Dictionary:
  return Global.input_manager.p1_input_buffer if player_id == 1 else Global.input_manager.p2_input_buffer;
#/_get_input_buffer

func _update_distance(delta: float, zone: CameraZone) -> void:
  var wanted := _get_wanted_distance(zone);
  _distance = lerpf(_distance, wanted, _sharpness_to_weight(CameraStats.DISTANCE_SHARPNESS, delta));
#/_update_distance

func _update_position(delta: float) -> void:
  var focus := _get_focus_point();
  if !_has_snapped:
    snap();
    return;
  #/if
  var horizontal_weight := _sharpness_to_weight(CameraStats.FOLLOW_SHARPNESS, delta);
  var vertical_weight := _sharpness_to_weight(CameraStats.VERTICAL_FOLLOW_SHARPNESS, delta);
  global_position = Vector3(
    lerpf(global_position.x, focus.x, horizontal_weight),
    lerpf(global_position.y, focus.y, vertical_weight),
    lerpf(global_position.z, focus.z, horizontal_weight)
  );
#/_update_position

func _apply() -> void:
  _pivot.rotation = Vector3(_pitch, _yaw, 0.0);
  _arm.spring_length = _distance;
#/_apply

func _get_focus_point() -> Vector3:
  var total := Vector3.ZERO;
  for target in targets: total += target.global_position;
  return total / targets.size() + Vector3.UP * CameraStats.FOCUS_HEIGHT;
#/_get_focus_point

func _get_average_velocity() -> Vector3:
  var total := Vector3.ZERO;
  for target in targets: total += Vector3(target.velocity.x, 0.0, target.velocity.z);
  return total / targets.size();
#/_get_average_velocity

# Default distance, pulled back to fit both players when sharing, or whatever a zone asks for.
func _get_wanted_distance(zone: CameraZone) -> float:
  if zone != null && zone.override_distance: return zone.distance;

  var wanted := CameraStats.DEFAULT_DISTANCE;
  if targets.size() > 1:
    var spread := targets[0].global_position.distance_to(targets[1].global_position);
    wanted = minf(wanted + spread * CameraStats.SHARED_DISTANCE_PER_METRE, CameraStats.MAX_SHARED_DISTANCE);
  #/if
  return wanted;
#/_get_wanted_distance

# The zone the first living target is standing in (P1 leads on a shared screen), or null.
# Ghosts don't count: they float through zones without triggering them.
func _get_active_zone() -> CameraZone:
  for target in targets:
    if target.is_alive(): return target.get_camera_zone();
  #/for
  return null;
#/_get_active_zone

# Turns a sharpness into a per-frame lerp weight that behaves the same at any frame rate.
func _sharpness_to_weight(sharpness: float, delta: float) -> float:
  return 1.0 - exp(-sharpness * delta);
#/_sharpness_to_weight
#endregion =========================================================================================
