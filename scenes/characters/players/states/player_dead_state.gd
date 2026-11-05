extends PlayerState
class_name PlayerDeadState

# Out of health and waiting for DeathManager to decide what happens next (ghost, respawn, Death's scene).
# No control; just falls and slides to a stop.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.carried_speed = 0.0;
#/enter

func physics_update(delta: float) -> void:
  if player.is_on_floor(): player.move_horizontally(delta, 0.0, 0.0, CharStats.RUN_DECELERATION);
  player.apply_gravity(delta, CharStats.FALL_GRAVITY_MULTIPLIER);
#/physics_update
