extends PlayerState
class_name PlayerWaterHurtState

# Hit while swimming or diving: a short bump away from whatever hit us, with no gravity, then back
# to floating (if we were near the surface) or diving. There's no fighting back underwater.
# On the surface the bump is flat and we keep floating; underwater it can push up or down too,
# but never above floating height.

var _on_surface := false;
var _time_without_air := 0.0;

func enter(previous: Enums.PLAYER_STATES) -> void:
  _on_surface = previous == Enums.PLAYER_STATES.SWIM || (previous == Enums.PLAYER_STATES.WATER_HURT && _on_surface);
  var away := player.global_position - player.hurt_from_position;
  if _on_surface: away.y = 0.0;
  if away.length() < 0.01: away = player.hurt_direction;
  player.velocity = away.normalized() * CharStats.WATER_HURT_KNOCKBACK;
#/enter

func physics_update(delta: float) -> void:
  if !player.env.is_in_water():
    player.return_to_neutral();
    return;
  #/if
  var floating_height := player.env.get_water_surface() - CharStats.SWIM_FLOAT_DEPTH;
  if time_in_state >= CharStats.WATER_HURT_TIME:
    var near_surface := player.global_position.y >= floating_height - CharStats.DIVE_SURFACE_SNAP;
    player.change_state(Enums.PLAYER_STATES.SWIM if _on_surface || near_surface else Enums.PLAYER_STATES.DIVE);
    return;
  #/if

  player.velocity = player.velocity.move_toward(Vector3.ZERO, CharStats.WATER_HURT_DRAG * delta);
  if _on_surface:
    player.velocity.y = (floating_height - player.global_position.y) * CharStats.SWIM_BOB_SHARPNESS;
  elif player.global_position.y >= floating_height:
    player.velocity.y = minf(player.velocity.y, 0.0);
  #/if

  if player.env.is_underwater(): _use_air(delta);
#/physics_update

# Air keeps running out while we're bumped around underwater, same as diving.
func _use_air(delta: float) -> void:
  player.env.use_air(delta);
  if player.env.air > 0.0: return;
  _time_without_air += delta;
  if _time_without_air >= CharStats.DROWN_DAMAGE_INTERVAL:
    _time_without_air = 0.0;
    player.drown();
  #/if
#/_use_air
