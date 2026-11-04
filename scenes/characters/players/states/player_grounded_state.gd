extends PlayerState
class_name PlayerGroundedState

# Standing or running. Speed follows how far the stick is pushed.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.can_flap = true;
  player.carried_speed = 0.0;
#/enter

func physics_update(delta: float) -> void:
  if !player.is_on_floor():
    player.change_state(Enums.PLAYER_STATES.FALL);
    return;
  #/if
  if player.try_ground_actions(): return;

  player.move_on_ground(delta);
  player.turn_toward_input(delta);
  player.apply_gravity(delta);
#/physics_update
