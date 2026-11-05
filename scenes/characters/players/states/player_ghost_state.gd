extends PlayerState
class_name PlayerGhostState

# Co-op only: whoever dies first floats as a ghost until their partner touches a checkpoint.
# Ghosts fly through walls, hover at their partner's height, and are leashed so the screen stays shared.
# The attack button is a "boo" that confuses nearby enemies, recharging over BOO_COOLDOWN.

const BOO_EFFECT_COLOR := Color(0.75, 0.85, 1.0, 0.5);
const BOO_EFFECT_TIME := 0.3;

var _time_since_boo := INF;

func enter(_previous: Enums.PLAYER_STATES) -> void:
  player.set_ghost_body(true);
  player.velocity = Vector3.ZERO;
  player.carried_speed = 0.0;
  _time_since_boo = INF;
#/enter

func exit(_next: Enums.PLAYER_STATES) -> void:
  player.set_ghost_body(false);
#/exit

func physics_update(delta: float) -> void:
  _time_since_boo += delta;
  if player.attack.is_buffered():
    player.attack.consume();
    _try_boo();
  #/if

  var partner := player.get_partner();
  var target := player.get_move_direction() * CharStats.GHOST_SPEED + _get_leash_pull(partner);
  var horizontal := Vector3(player.velocity.x, 0.0, player.velocity.z).move_toward(target, CharStats.GHOST_ACCELERATION * delta);
  player.velocity.x = horizontal.x;
  player.velocity.z = horizontal.z;
  player.turn_toward_input(delta);

  # Drift to hovering height above the partner.
  if partner == null:
    player.velocity.y = 0.0;
  else:
    var wanted_height := partner.global_position.y + CharStats.GHOST_HOVER_HEIGHT;
    player.velocity.y = (wanted_height - player.global_position.y) * CharStats.GHOST_VERTICAL_SHARPNESS;
  #/if
#/physics_update

# Past the leash, the ghost is pulled back toward its partner, harder the further it strays.
func _get_leash_pull(partner: PlayerCharacter) -> Vector3:
  if partner == null: return Vector3.ZERO;
  var offset := player.global_position - partner.global_position;
  offset.y = 0.0;
  var past_leash := offset.length() - CharStats.GHOST_LEASH_DISTANCE;
  if past_leash <= 0.0: return Vector3.ZERO;
  return -offset.normalized() * past_leash * CharStats.GHOST_LEASH_PULL;
#/_get_leash_pull

func _try_boo() -> void:
  if _time_since_boo < CharStats.BOO_COOLDOWN: return;
  _time_since_boo = 0.0;
  for enemy in player.get_tree().get_nodes_in_group("enemies"):
    if enemy.has_method("confuse") && enemy.global_position.distance_to(player.global_position) <= CharStats.BOO_RADIUS:
      enemy.confuse(CharStats.BOO_CONFUSE_TIME);
    #/if
  #/for
  _play_boo_effect();
#/_try_boo

# Placeholder: a pale sphere that swells to the boo's radius and fades.
func _play_boo_effect() -> void:
  var material := StandardMaterial3D.new();
  material.albedo_color = BOO_EFFECT_COLOR;
  material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;
  var mesh := SphereMesh.new();
  mesh.material = material;
  var effect := MeshInstance3D.new();
  effect.mesh = mesh;
  player.add_child(effect);
  effect.scale = Vector3.ONE * 0.1;

  var tween := effect.create_tween().set_parallel();
  tween.tween_property(effect, "scale", Vector3.ONE * CharStats.BOO_RADIUS * 2.0, BOO_EFFECT_TIME);
  tween.tween_property(material, "albedo_color:a", 0.0, BOO_EFFECT_TIME);
  tween.chain().tween_callback(effect.queue_free);
#/_play_boo_effect
