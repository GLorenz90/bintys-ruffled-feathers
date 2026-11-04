extends PlayerState
class_name PlayerRollState

# Dodge roll along the ground at a fixed speed. Rolls toward the stick, or straight ahead if it's centred.
# Jumping out of a roll keeps the roll's speed through the jump (see PlayerJumpState).

var _direction := Vector3.ZERO;

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.snap_toward_input();
  _direction = player.get_facing_direction();
  player.set_roll_shape(true);
#/enter

func exit(_next: Enums.PLAYER_STATES) -> void:
  player.set_roll_shape(false);
#/exit

func physics_update(delta: float) -> void:
  if !player.is_on_floor() && !player.can_coyote_jump():
    player.carried_speed = CharStats.ROLL_SPEED;
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if
  if player.jump.was_pressed_recently():
    player.jump.consume();
    player.change_state(Enums.PLAYER_STATES.JUMP);
    return;
  #/if
  if time_in_state >= CharStats.ROLL_TIME:
    player.return_to_neutral();
    return;
  #/if

  player.velocity.x = _direction.x * CharStats.ROLL_SPEED;
  player.velocity.z = _direction.z * CharStats.ROLL_SPEED;
  player.apply_gravity(delta);
#/physics_update
