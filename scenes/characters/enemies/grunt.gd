extends Character
class_name Grunt

# A basic enemy. Stands around until a living player comes within sight, then chases them
# and hurts them on contact. Getting hit stuns it briefly and knocks it back. A ghost's boo
# confuses it: it stops, spins, and is harmless for a moment. Drops silver (and sometimes health) when defeated.
# Numbers live in CharStats under ENEMY: GRUNT.

enum STATES { IDLE, CHASE, STUNNED, CONFUSED, DEFEATED }

const BODY_COLOR := Color(0.85, 0.25, 0.2);
const CONFUSED_SPIN_SPEED := 4.0;   # Radians per second.
const DEFEAT_TIME := 0.25;
const SILVER_SCENE: PackedScene = preload("res://scenes/items/pickups/small_silver.tscn");
const CRUMB_SCENE: PackedScene = preload("res://scenes/items/pickups/health_crumb.tscn");
const SLICE_SCENE: PackedScene = preload("res://scenes/items/pickups/health_slice.tscn");

var state: STATES = STATES.IDLE;
var _time_in_state := 0.0;
var _confused_duration := 0.0;
var _target: PlayerCharacter;
var _flash: EnemyBodyFlash;

@onready var _contact_hitbox: Area3D = $ContactHitbox;
@onready var _confused_label: Label3D = $ConfusedLabel;

#region BUILT IN ===================================================================================
func _ready() -> void:
  add_to_group("enemies");
  _max_health = CharStats.GRUNT_MAX_HEALTH;
  _cur_health = _max_health;
  $InvulnTimer.wait_time = 0.05; # Short, so every swing of a combo lands.
  _flash = EnemyBodyFlash.new($Model/Body, BODY_COLOR);
  _set_state(STATES.IDLE);
#/_ready

func _physics_process(delta: float) -> void:
  _time_in_state += delta;
  match state:
    STATES.IDLE: _update_idle(delta);
    STATES.CHASE: _update_chase(delta);
    STATES.STUNNED: _update_stunned(delta);
    STATES.CONFUSED: _update_confused(delta);
    STATES.DEFEATED: return;
  #/match

  if state == STATES.IDLE || state == STATES.CHASE: _hurt_touching_players();
  velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta;
  move_and_slide();
#/_physics_process
#endregion =========================================================================================

#region PUBLIC =====================================================================================
func confuse(duration: float) -> void:
  if state == STATES.DEFEATED: return;
  _confused_duration = duration;
  _set_state(STATES.CONFUSED);
#/confuse

func get_state_name() -> String:
  return STATES.keys()[state];
#/get_state_name
#endregion =========================================================================================

#region STATES =====================================================================================
func _update_idle(delta: float) -> void:
  _target = _find_nearest_player(CharStats.GRUNT_SIGHT_RANGE);
  if _target != null:
    _set_state(STATES.CHASE);
    return;
  #/if
  _steer(Vector3.ZERO, delta);
#/_update_idle

func _update_chase(delta: float) -> void:
  if !_is_valid_target(_target, CharStats.GRUNT_LOSE_RANGE):
    _target = _find_nearest_player(CharStats.GRUNT_SIGHT_RANGE);
    if _target == null:
      _set_state(STATES.IDLE);
      return;
    #/if
  #/if
  var toward := _target.global_position - global_position;
  toward.y = 0.0;
  _steer(toward.normalized() * CharStats.GRUNT_SPEED, delta);
  _turn_toward(toward, delta);
#/_update_chase

func _update_stunned(delta: float) -> void:
  if _time_in_state >= CharStats.GRUNT_STUN_TIME:
    _set_state(STATES.CHASE if _target != null else STATES.IDLE);
    return;
  #/if
  var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, CharStats.GRUNT_KNOCKBACK_FRICTION * delta);
  velocity.x = horizontal.x;
  velocity.z = horizontal.z;
#/_update_stunned

func _update_confused(delta: float) -> void:
  if _time_in_state >= _confused_duration:
    _set_state(STATES.IDLE);
    return;
  #/if
  _steer(Vector3.ZERO, delta);
  rotation.y += CONFUSED_SPIN_SPEED * delta;
#/_update_confused

func _set_state(new_state: STATES) -> void:
  state = new_state;
  _time_in_state = 0.0;
  _confused_label.visible = state == STATES.CONFUSED;
#/_set_state
#endregion =========================================================================================

#region HELPERS ====================================================================================
func _steer(target_velocity: Vector3, delta: float) -> void:
  var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(target_velocity, CharStats.GRUNT_ACCELERATION * delta);
  velocity.x = horizontal.x;
  velocity.z = horizontal.z;
#/_steer

func _turn_toward(direction: Vector3, delta: float) -> void:
  if direction.is_zero_approx(): return;
  var target_angle := atan2(-direction.x, -direction.z);
  rotation.y = lerp_angle(rotation.y, target_angle, clampf(CharStats.GRUNT_TURN_SPEED * delta, 0.0, 1.0));
#/_turn_toward

func _find_nearest_player(max_distance: float) -> PlayerCharacter:
  var nearest: PlayerCharacter = null;
  var nearest_distance := max_distance;
  for player in Global.get_living_players():
    var distance := player.global_position.distance_to(global_position);
    if distance <= nearest_distance:
      nearest = player;
      nearest_distance = distance;
    #/if
  #/for
  return nearest;
#/_find_nearest_player

func _is_valid_target(player: PlayerCharacter, max_distance: float) -> bool:
  return player != null && is_instance_valid(player) && player.is_alive() \
    && player.global_position.distance_to(global_position) <= max_distance;
#/_is_valid_target

func _hurt_touching_players() -> void:
  for body in _contact_hitbox.get_overlapping_bodies():
    if body is PlayerCharacter && body.is_alive():
      body.hit(CharStats.GRUNT_CONTACT_DAMAGE, global_position);
    #/if
  #/for
#/_hurt_touching_players

# Silver every time, plus a roll for health (see ENEMY DROPS in CharStats).
func _drop_loot() -> void:
  for i in CharStats.GRUNT_SILVER_DROP: _drop(SILVER_SCENE);

  var roll := randf();
  if roll < CharStats.ENEMY_DROP_SLICE_CHANCE:
    _drop(SLICE_SCENE);
  elif roll < CharStats.ENEMY_DROP_SLICE_CHANCE + CharStats.ENEMY_DROP_CRUMB_CHANCE:
    _drop(CRUMB_SCENE);
  #/if
#/_drop_loot

func _drop(pickup_scene: PackedScene) -> void:
  var pickup: RigidBody3D = pickup_scene.instantiate();
  get_parent().add_child(pickup);
  pickup.global_position = global_position + Vector3.UP;
  pickup.apply_central_impulse(Vector3(randf_range(-1.0, 1.0), 2.5, randf_range(-1.0, 1.0)) * 0.05);
#/_drop
#endregion =========================================================================================

#region CHARACTER OVERRIDES ========================================================================
func _on_hurt(_amount: int, from_position: Vector3, knockback: float) -> void:
  _flash.flash(self);
  var push := get_knockback_direction(from_position) * knockback;
  velocity.x = push.x;
  velocity.z = push.z;
  if _target == null: _target = _find_nearest_player(CharStats.GRUNT_LOSE_RANGE);
  _set_state(STATES.STUNNED);
#/_on_hurt

func _on_health_depleted() -> void:
  _set_state(STATES.DEFEATED);
  _flash.flash(self);
  collision_layer = 0;
  collision_mask = 0;
  _contact_hitbox.set_deferred("monitoring", false);
  _drop_loot.call_deferred();

  var tween := create_tween();
  tween.tween_property($Model, "scale", Vector3(1.4, 0.2, 1.4), DEFEAT_TIME);
  tween.tween_callback(queue_free);
#/_on_health_depleted
#endregion =========================================================================================
