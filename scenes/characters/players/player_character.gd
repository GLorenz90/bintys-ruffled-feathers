extends Character
class_name PlayerCharacter;

signal action_changed(prev_action: Enums.CHAR_STATES, next_action: Enums.CHAR_STATES);

@export var char_type:Enums.CHARACTERS;
@export var is_p1 := true;
@export var debug_actions := false;

const SHAPE_NORMAL: CapsuleShape3D = preload("res://resources/shapes/player_shape_normal.tres");
const SHAPE_ROLL: CapsuleShape3D = preload("res://resources/shapes/player_shape_roll.tres");
const BODY_NORMAL: CapsuleMesh = preload("res://resources/meshes/test_body.tres");
const BODY_ROLL: CapsuleMesh = preload("res://resources/meshes/test_body_short.tres");
var _swing_attack_1: PackedScene = preload("res://scenes/attacks/swing_attack_1.tscn");
var _swing_attack_2: PackedScene = preload("res://scenes/attacks/swing_attack_2.tscn");

#region PRIVATE VARS ===============================================================================
var _input_buffer;
var _in_move := Vector2.ZERO;
var _in_jump := false;
var _in_roll := false;
var _in_attack := false;
var _in_interact := false;
var _in_use_item := false;
var _in_next_item := false;
var _in_prev_item := false;

# Seconds since each action was last pressed. INF = nothing buffered.
var _buf_jump := INF;
var _buf_roll := INF;
var _buf_attack := INF;
var _buf_interact := INF;

var _action: Enums.CHAR_STATES = Enums.CHAR_STATES.INIT;
var _action_time := 0.0;
var _cur_action_duration := -1.0;
var _recoil_dir := Vector3.ZERO;
var _air_momentum := Vector3.ZERO;
#endregion =========================================================================================

#region BUILT IN FUNCTIONS =========================================================================
func _ready() -> void:
  super();
  _max_health = CharStats.MAX_HEALTH;
  _cur_health = CharStats.P1_CURRENT_HEALTH if is_p1 else CharStats.P2_CURRENT_HEALTH;
  if is_p1:
    Global.p1_char = self;
  else:
    Global.p2_char = self;
  _return_to_neutral_state();

  Signals.end_interaction.connect(_end_interact);
#/_ready

func _physics_process(delta: float) -> void:
  super(delta);
  _process_inputs(delta);
  _process_action(delta);
  _process_movement(delta);
#/_physics_process
#endregion =========================================================================================

#region PRIVATE FUNCTIONS ==========================================================================
func _process_inputs(_delta: float) -> void:
  _input_buffer = Global.input_manager.p1_input_buffer if is_p1 else Global.input_manager.p2_input_buffer;
  _in_move = _input_buffer[Enums.INPUT_BUFFER.MOVE];
  _in_jump = _input_buffer[Enums.INPUT_BUFFER.JUMP_HELD];
  _in_roll = _input_buffer[Enums.INPUT_BUFFER.ROLL_PRESSED];
  _in_attack = _input_buffer[Enums.INPUT_BUFFER.ATTACK_PRESSED];
  _in_interact = _input_buffer[Enums.INPUT_BUFFER.INTERACT_PRESSED];
  _in_use_item = _input_buffer[Enums.INPUT_BUFFER.USE_ITEM_PRESSED];
  _in_next_item = _input_buffer[Enums.INPUT_BUFFER.NEXT_ITEM_PRESSED];
  _in_prev_item = _input_buffer[Enums.INPUT_BUFFER.PREV_ITEM_PRESSED];

  _buf_jump = _input_buffer[Enums.INPUT_BUFFER.JUMP_HELD_TIME];
  _buf_roll = _input_buffer[Enums.INPUT_BUFFER.ROLL_HELD_TIME];
  _buf_attack = _input_buffer[Enums.INPUT_BUFFER.ATTACK_HELD_TIME];
  _buf_interact = _input_buffer[Enums.INPUT_BUFFER.INTERACT_HELD_TIME];
#/_process_inputs

func _is_buffered(time_since_press: float) -> bool:
  return time_since_press <= CharStats.MAX_INPUT_BUFFER_TIME;
#/_is_buffered

func _move_dir() -> Vector3:
  return Vector3(_in_move.x, 0.0, _in_move.y);
#/_move_dir

func _process_movement(delta: float) -> void:
  var cur_rule := _get_current_rules();
  var horizontal := Vector3.ZERO;

  match _action:
    Enums.CHAR_STATES.ROLLING:
      horizontal = -global_basis.z * CharStats.ROLL_SPEED;
    Enums.CHAR_STATES.HURT:
      # Knockback that eases out over the hurt time.
      var falloff := 1.0 - clampf(_action_time / cur_rule.state_duration, 0.0, 1.0);
      horizontal = _recoil_dir * CharStats.HURT_KNOCKBACK_SPEED * falloff;
    _:
      # TODO: Interpolate
      var walk := _move_dir().normalized() * CharStats.WALK_SPEED;
      if _air_momentum.is_zero_approx():
        horizontal = walk;
      else:
        # Carried momentum holds its speed and direction. The stick can nudge it sideways
        # or pull back to shorten the jump, but can't push past the carried speed.
        horizontal = (_air_momentum + walk).limit_length(_air_momentum.length());
      #/if
  #/match

  velocity.x = horizontal.x;
  velocity.z = horizontal.z;

  if is_on_floor() && velocity.y <= 0.0:
    velocity.y = 0.0;
  else:
    if velocity.y <= 0.0 && velocity.y > -2.5: velocity.y = -2.5;
    velocity.y = clamp(velocity.y - (_gravity * delta), -Global.MAX_Y_SPEED, Global.MAX_Y_SPEED);
  #/if
  move_and_slide();

  if is_on_floor():
    _air_momentum = Vector3.ZERO;
  #/if

  if cur_rule.turn && !_in_move.is_zero_approx():
    # TODO: Interpolate
    _face(_move_dir());
  #/if
#/_process_movement

func _face(dir: Vector3) -> void:
  look_at(global_position + dir, Vector3.UP);
#/_face

func _die():
  pass;
  # Either become ghost, or go to game over screen.
#/_die
#endregion =========================================================================================

#region ACTION STATE ===============================================================================
func _rules_for(state: Enums.CHAR_STATES) -> Dictionary:
  return CharStats.ACTION_RULES[state];
#/_rules_for

func _get_current_rules() -> Dictionary:
  return _rules_for(_action);
#/_rules

func _attempt_action(target: Enums.CHAR_STATES) -> void:
  var current_rule := _get_current_rules();
  var target_rule = _rules_for(target);

  # Deny action if...
  if target_rule.ground_only && !is_on_floor() \
    || (target_rule.flag != null && !current_rule[target_rule.flag]) \
    || current_rule.interrupt_after < 0.0 \
    || _action_time < current_rule.interrupt_after \
    || (target == Enums.CHAR_STATES.INTERACT && _find_interactable() == null):
    return;
  #/if

  _set_state(target);
#/_attempt_action

func _is_neutral_state(target: Enums.CHAR_STATES) -> bool:
  return [Enums.CHAR_STATES.INIT, Enums.CHAR_STATES.FREE, Enums.CHAR_STATES.MIDAIR].has(target)
#/_is_neutral_state

func _return_to_neutral_state() -> void:
  _set_state(Enums.CHAR_STATES.FREE if is_on_floor() else Enums.CHAR_STATES.MIDAIR);
#/_return_to_neutral_state

func _set_state(target: Enums.CHAR_STATES) -> void:
  # State is not changing
  if(_action == target): return;

  var prev: Enums.CHAR_STATES = _action;
  _action = target;
  _action_time = 0.0;
  _cur_action_duration = _rules_for(target).state_duration;

  # Swap to the short capsule while rolling, keeping its base on the floor.
  if target == Enums.CHAR_STATES.ROLLING || prev == Enums.CHAR_STATES.ROLLING:
    var shape: CapsuleShape3D = SHAPE_ROLL if target == Enums.CHAR_STATES.ROLLING else SHAPE_NORMAL;
    var mesh: CapsuleMesh = BODY_ROLL if target == Enums.CHAR_STATES.ROLLING else BODY_NORMAL;
    $Collision.shape = shape;
    $Collision.position.y = shape.height * 0.5;
    $Model/Body.mesh = mesh;
    $Model/Body.position.y  = $Collision.position.y;
  #/if

  match(target):
    Enums.CHAR_STATES.INIT, \
    Enums.CHAR_STATES.FREE, \
    Enums.CHAR_STATES.MIDAIR:
      pass;
    Enums.CHAR_STATES.JUMPING: _start_jump(prev);
    Enums.CHAR_STATES.ROLLING: _start_roll();
    Enums.CHAR_STATES.INTERACT: _start_interact();
    Enums.CHAR_STATES.SWORD_1, \
    Enums.CHAR_STATES.SWORD_2:
      _start_attack();
    Enums.CHAR_STATES.HURT:
      _air_momentum = Vector3.ZERO;
    _: pass;

  if debug_actions:
    print("%s: %s -> %s" % [name, Enums.CHAR_STATES.keys()[prev], Enums.CHAR_STATES.keys()[target]]);
  #/if
  action_changed.emit(prev, target);
#/_set_state

func _process_action(delta: float) -> void:
  _action_time += delta;

  # Timed state is ending
  if _cur_action_duration >= 0.0 && _action_time >= _cur_action_duration:
    _return_to_neutral_state();

  # If we're in a neutral state, attempt to enter neutral state, to see if we go from midair to free and so on.
  if _is_neutral_state(_action):
    _return_to_neutral_state();

  if (_action == Enums.CHAR_STATES.JUMPING) && (velocity.y <= 0 || !_in_jump):
    velocity.y = velocity.y/2.0;
    _return_to_neutral_state();

  if _in_roll && _is_buffered(_buf_roll): _attempt_action(Enums.CHAR_STATES.ROLLING);

  if _in_interact && _is_buffered(_buf_interact): _attempt_action(Enums.CHAR_STATES.INTERACT);

  if _in_jump && _is_buffered(_buf_jump): _attempt_action(Enums.CHAR_STATES.JUMPING);

  if _in_attack && _is_buffered(_buf_attack):
    var next_attack: Enums.CHAR_STATES = _next_attack_state();
    _attempt_action(next_attack);
  #/if
#/_process_action

func _next_attack_state() -> Enums.CHAR_STATES:
  return Enums.CHAR_STATES.SWORD_2 if _action == Enums.CHAR_STATES.SWORD_1 else Enums.CHAR_STATES.SWORD_1;
#/_next_attack_state

func _start_jump(prev: Enums.CHAR_STATES) -> void:
  velocity.y = CharStats.JUMP_VELOCITY;
  # Jumping out of a roll keeps the roll's speed and direction until we land.
  if prev == Enums.CHAR_STATES.ROLLING:
    _air_momentum = -global_basis.z * CharStats.ROLL_SPEED;
  #/if
#/_start_jump

func _start_roll() -> void:
  # Roll toward the stick if it's held, otherwise the way we're facing.
  if !_in_move.is_zero_approx():
    _face(_move_dir());
  #/if
#/_start_roll

func _start_attack() -> void:
  # Turning is locked during swings, so snap to the stick on the first frame.
  if !_in_move.is_zero_approx():
    _face(_move_dir());
  #/if
  match(_action):
    Enums.CHAR_STATES.SWORD_1:
      _spawn_attack(_swing_attack_1, _get_current_rules().state_duration);
    Enums.CHAR_STATES.SWORD_2:
      _spawn_attack(_swing_attack_2, _get_current_rules().state_duration);
  #/match
#/_start_attack

func _find_interactable() -> Node3D:
  # TODO: Check an Area3D in front of the player for interactables (signs, chests, pots).
  return null;
#/_find_interactable

func _start_interact() -> void:
  var interacted = _find_interactable();
  if interacted != null:
    _invulnerable = true;
    #interacted.interact();
  #/if
#/_start_interact

func _end_interact() -> void:
  _invulnerable = false;
  _return_to_neutral_state();
#/end_interact
#endregion =========================================================================================

#region PUBLIC FUNCTIONS ===========================================================================
#endregion =========================================================================================
