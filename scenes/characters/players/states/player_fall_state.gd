extends PlayerState
class_name PlayerFallState

# In the air and not rising under our own power: after a jump's peak, or after walking off a ledge.
# A fresh jump press here is a coyote jump (just left a ledge) or starts the wing flap.
# Right above the ground it's neither: the press stays buffered and becomes a jump on landing.

func physics_update(delta: float) -> void:
  if player.is_on_floor():
    player.change_state(Enums.PLAYER_STATES.GROUNDED);
    return;
  #/if
  if player.jump.is_buffered():
    if player.can_coyote_jump():
      player.jump.consume();
      player.change_state(Enums.PLAYER_STATES.JUMP);
      return;
    elif player.can_flap && !player.is_ground_within(CharStats.FLAP_MIN_HEIGHT):
      player.jump.consume();
      player.change_state(Enums.PLAYER_STATES.FLAP);
      return;
    #/if
  #/if
  if player.attack.is_buffered():
    player.attack.consume();
    player.change_state(Enums.PLAYER_STATES.ATTACK);
    return;
  #/if

  player.move_in_air(delta);
  player.turn_toward_input(delta);
  var multiplier := CharStats.FALL_GRAVITY_MULTIPLIER if player.velocity.y <= 0.0 else 1.0;
  player.apply_gravity(delta, multiplier);
#/physics_update
