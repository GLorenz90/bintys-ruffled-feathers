extends PlayerState
class_name PlayerHurtState

# Knocked back by a hit. Control comes back after HURT_TIME; invulnerability (the blinking) lasts longer.

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.velocity = player.hurt_direction * CharStats.HURT_KNOCKBACK;
  player.velocity.y = CharStats.HURT_KNOCKUP;
  player.carried_speed = 0.0;
#/enter

func physics_update(delta: float) -> void:
  if time_in_state >= CharStats.HURT_TIME && (player.is_on_floor() || player.velocity.y <= 0.0):
    player.return_to_neutral();
    return;
  #/if

  # No steering; the knockback just slides to a stop on the ground.
  if player.is_on_floor(): player.move_horizontally(delta, 0.0, 0.0, CharStats.RUN_DECELERATION);
  player.apply_gravity(delta, CharStats.FALL_GRAVITY_MULTIPLIER);
#/physics_update
