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
# Players can steer it with the right stick (or arrows / right-mouse drag for P1). After MANUAL_HOLD_TIME
# without steering it goes back to following on its own. A CameraZone the players stand in can override it.
# All numbers live in CameraStats.

#region PUBLIC VARS ================================================================================
var targets: Array[PlayerCharacter] = [];
var controller_ids: Array[int] = [];      # Which players' look input steers this camera.
#endregion =========================================================================================

#region PRIVATE VARS ===============================================================================
var _yaw := 0.0;                           # Radians.
var _pitch := deg_to_rad(CameraStats.DEFAULT_PITCH);
var _distance := CameraStats.DEFAULT_DISTANCE;
var _time_since_manual := INF;
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
  _time_since_manual = other._time_since_manual;
  _has_snapped = true;
  _apply();
#/copy_from

func get_yaw() -> float:
  return _yaw;
#/get_yaw
#endregion =========================================================================================

#region PRIVATE ====================================================================================
func _update_rotation(delta: float, zone: CameraZone) -> void:
  var stick := Vector2.ZERO;
  var mouse := Vector2.ZERO;
  for player_id in controller_ids:
    var buffer: Dictionary = Global.input_manager.p1_input_buffer if player_id == 1 else Global.input_manager.p2_input_buffer;
    stick += buffer[Enums.INPUT_BUFFER.LOOK];
    mouse += buffer[Enums.INPUT_BUFFER.LOOK_MOUSE];
  #/for
  stick = stick.limit_length(1.0);

  if !stick.is_zero_approx() || !mouse.is_zero_approx():
    _time_since_manual = 0.0;
    _yaw -= deg_to_rad(stick.x * CameraStats.STICK_YAW_SPEED * delta + mouse.x * CameraStats.MOUSE_SENSITIVITY);
    _pitch -= deg_to_rad(stick.y * CameraStats.STICK_PITCH_SPEED * delta + mouse.y * CameraStats.MOUSE_SENSITIVITY);
    _pitch = clampf(_pitch, deg_to_rad(CameraStats.MIN_PITCH), deg_to_rad(CameraStats.MAX_PITCH));
    return;
  #/if
  _time_since_manual += delta;

  var blend := _sharpness_to_weight(CameraStats.ZONE_BLEND_SHARPNESS, delta);
  if zone != null && zone.fixed_angle:
    _yaw = lerp_angle(_yaw, deg_to_rad(zone.yaw_degrees), blend);
    _pitch = lerp_angle(_pitch, deg_to_rad(zone.pitch_degrees), blend);
    return;
  #/if
  if _time_since_manual < CameraStats.MANUAL_HOLD_TIME: return;

  # Auto turn: drift behind the players when they run sideways across the screen.
  var right := Vector3(cos(_yaw), 0.0, -sin(_yaw));
  var sideways_speed := _get_average_velocity().dot(right);
  _yaw -= sideways_speed * CameraStats.AUTO_TURN_RATE * delta;

  var wanted_pitch := deg_to_rad(zone.pitch_degrees if zone != null && zone.override_pitch else CameraStats.DEFAULT_PITCH);
  _pitch = move_toward(_pitch, wanted_pitch, deg_to_rad(CameraStats.PITCH_RETURN_SPEED) * delta);
#/_update_rotation

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

# The zone the first target is standing in (P1 leads on a shared screen), or null.
func _get_active_zone() -> CameraZone:
  return targets[0].get_camera_zone();
#/_get_active_zone

# Turns a sharpness into a per-frame lerp weight that behaves the same at any frame rate.
func _sharpness_to_weight(sharpness: float, delta: float) -> float:
  return 1.0 - exp(-sharpness * delta);
#/_sharpness_to_weight
#endregion =========================================================================================
