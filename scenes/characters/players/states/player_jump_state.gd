extends PlayerState
class_name PlayerJumpState

# Rising after a jump. Letting go of jump early cuts the jump short, so a tap is a small hop.

func enter(previous: Enums.PLAYER_STATES) -> void:
  player.velocity.y = CharStats.JUMP_VELOCITY;
  player.time_since_grounded = INF; # A jump uses up coyote time.

  # Jumping out of a roll keeps the roll's speed until landing.
  if previous == Enums.PLAYER_STATES.ROLL: player.carried_speed = CharStats.ROLL_SPEED;
#/enter

func physics_update(delta: float) -> void:
  if !player.jump.held:
    player.velocity.y *= CharStats.JUMP_CUT_MULTIPLIER;
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if
  if player.velocity.y <= 0.0:
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if
  if player.attack.is_buffered():
    player.attack.consume();
    player.change_state(Enums.PLAYER_STATES.ATTACK);
    return;
  #/if

  player.move_in_air(delta);
  player.turn_toward_input(delta);
  player.apply_gravity(delta);
#/physics_update
